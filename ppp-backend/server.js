// server.js
require('dotenv').config();
const express = require('express');
const Stripe = require('stripe');
const { ethers } = require('ethers');
const fs = require('fs');
//const readline = require('readline');
const readlineSync = require('readline-sync');

const stripe = Stripe(process.env.STRIPE_SECRET_KEY);
const app = express();

let processor;
let currentTokenId = 1;

// Password prompt (hidden input)
// function askPassword(prompt) {
//     return new Promise((resolve) => {
//         const rl = readline.createInterface({
//             input: process.stdin,
//             output: process.stdout
//         });

//         process.stdout.write(prompt);
//         process.stdin.setRawMode(true);
//         process.stdin.resume();

//         let password = '';
//         process.stdin.on('data', (char) => {
//             char = char.toString();
//             if (char === '\n' || char === '\r') {
//                 process.stdin.setRawMode(false);
//                 rl.close();
//                 console.log('');
//                 resolve(password);
//             } else if (char === '\u007F') {
//                 password = password.slice(0, -1);
//             } else {
//                 password += char;
//             }
//         });
//     });
// }

async function initWallet() {
    const provider = new ethers.JsonRpcProvider(process.env.RPC_URL);
    const keystorePath = process.env.KEYSTORE_PATH;
    const keystore = fs.readFileSync(keystorePath, 'utf8');

    //const password = await askPassword('🔐 Enter keystore password: ');
    const password = readlineSync.question('🔐 Enter keystore password: ', {
        hideEchoBack: true
    });

    console.log('   Decrypting...');
    const wallet = await ethers.Wallet.fromEncryptedJson(keystore, password);

    processor = new ethers.Contract(
        process.env.PROCESSOR_ADDRESS,
        ['function processPayment(bytes32,address,uint256,uint256) returns (bool)'],
        wallet.connect(provider)
    );

    console.log('✅ Wallet loaded:', wallet.address);
}

// Webhook endpoint
app.post('/webhook', express.raw({ type: 'application/json' }), async (req, res) => {
    const sig = req.headers['stripe-signature'];

    let event;
    try {
        event = stripe.webhooks.constructEvent(
            req.body,
            sig,
            process.env.STRIPE_WEBHOOK_SECRET
        );
    } catch (err) {
        console.error('Webhook error:', err.message);
        return res.status(400).send(`Webhook Error: ${err.message}`);
    }

    if (event.type === 'checkout.session.completed') {
        const session = event.data.object;

        // DEBUG: Log the full custom_fields
        console.log('📋 Custom fields:', JSON.stringify(session.custom_fields, null, 2));

        const walletField = session.custom_fields?.find(f =>
            f.key === 'buyerwalletaddress'
        );
        const buyerWallet = walletField?.text?.value || session.client_reference_id;

        console.log('👛 Extracted wallet:', buyerWallet);

        if (!buyerWallet || !ethers.isAddress(buyerWallet)) {
            console.error('❌ Invalid wallet address:', buyerWallet);
            return res.status(400).send('Invalid wallet address');
        }

        const amountCents = session.amount_total;
        const paymentId = session.payment_intent;
        const usdcAmount = BigInt(amountCents) * BigInt(10000);

        console.log(`\n✅ Payment received!`);
        console.log(`   Buyer: ${buyerWallet}`);
        console.log(`   Token: #${currentTokenId}`);
        console.log(`   Amount: $${amountCents / 100}`);

        try {
            console.log(`\n🔄 Processing on-chain...`);
            const tx = await processor.processPayment(
                ethers.id(paymentId),
                buyerWallet,
                BigInt(currentTokenId),
                usdcAmount
            );
            console.log(`   Tx: ${tx.hash}`);
            await tx.wait();
            console.log(`\n🎉 NFT #${currentTokenId} delivered to ${buyerWallet}!\n`);
            currentTokenId++;
        } catch (err) {
            console.error('❌ Blockchain error:', err.message);
            return res.status(500).send('Blockchain processing failed');
        }
    }

    res.json({ received: true });
});

// Start server after wallet is loaded
initWallet().then(() => {
    app.listen(3000, () => {
        console.log(`\n🚀 Webhook server running on port 3000`);
        console.log(`   Processor: ${process.env.PROCESSOR_ADDRESS}`);
        console.log(`📦 Next token to sell: #${currentTokenId}\n`);
    });
}).catch(err => {
    console.error('❌ Failed to load wallet:', err.message);
    process.exit(1);
});