// server.js
require('dotenv').config();
const express = require('express');
const Stripe = require('stripe');
const { ethers } = require('ethers');

const stripe = Stripe(process.env.STRIPE_SECRET_KEY);
const app = express();

// Setup provider and contract ONCE at startup (not per request)
const provider = new ethers.JsonRpcProvider(process.env.RPC_URL);
const wallet = new ethers.Wallet(process.env.PRIVATE_KEY, provider);
const processor = new ethers.Contract(
    process.env.PROCESSOR_ADDRESS,
    ['function processPayment(bytes32,address,uint256,uint256) returns (bool)'],
    wallet
);

// Current token ID to sell
let currentTokenId = 1;

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

        // Get wallet from custom field (search by key for reliability)
        const walletField = session.custom_fields?.find(f =>
            f.key === 'walletaddress' || f.key === 'wallet_address'
        );
        const buyerWallet = walletField?.text?.value || session.client_reference_id;

        // Validate wallet address
        if (!buyerWallet || !ethers.isAddress(buyerWallet)) {
            console.error('❌ Invalid wallet address:', buyerWallet);
            return res.status(400).send('Invalid wallet address');
        }

        const amountCents = session.amount_total;
        const paymentId = session.payment_intent;

        console.log(`\n✅ Payment received!`);
        console.log(`   Buyer: ${buyerWallet}`);
        console.log(`   Token: #${currentTokenId}`);
        console.log(`   Amount: $${amountCents / 100}`);

        // Convert cents to USDC (6 decimals)
        const usdcAmount = BigInt(amountCents) * BigInt(10000);

        // Process with error handling
        try {
            await processPaymentOnChain(paymentId, buyerWallet, currentTokenId, usdcAmount);
            currentTokenId++;
        } catch (err) {
            console.error('❌ Blockchain error:', err.message);
            return res.status(500).send('Blockchain processing failed');
        }
    }

    res.json({ received: true });
});

async function processPaymentOnChain(paymentId, buyer, tokenId, amount) {
    console.log(`\n🔄 Processing on-chain...`);

    const tx = await processor.processPayment(
        ethers.id(paymentId),
        buyer,
        BigInt(tokenId),
        amount
    );

    console.log(`   Tx: ${tx.hash}`);
    await tx.wait();
    console.log(`\n🎉 NFT #${tokenId} delivered to ${buyer}!\n`);
}

app.listen(3000, () => {
    console.log(`\n🚀 Webhook server running on port 3000`);
    console.log(`   Processor: ${process.env.PROCESSOR_ADDRESS}`);
    console.log(`📦 Next token to sell: #${currentTokenId}\n`);
});