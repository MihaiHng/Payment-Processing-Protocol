// server.js
require('dotenv').config();
const express = require('express');
const Stripe = require('stripe');
const { ethers } = require('ethers');
const fs = require('fs');
const readlineSync = require('readline-sync');
const { Resend } = require('resend');

const resend = new Resend(process.env.RESEND_API_KEY);
const stripe = Stripe(process.env.STRIPE_SECRET_KEY);
const app = express();

let processor;
let currentTokenId = 4;

async function getNFTMetadata(tokenId) {
    const baseURI = process.env.NFT_BASE_URI;

    // Convert IPFS URI to HTTP gateway
    const ipfsGateway = baseURI
        .replace('ipfs://', 'https://ipfs.io/ipfs/');

    const metadataURL = `${ipfsGateway}${tokenId}`;
    console.log(`📄 Fetching metadata from: ${metadataURL}`);

    const response = await fetch(metadataURL);
    const metadata = await response.json();

    return metadata;
}

async function sendTicketEmail(buyerEmail, tokenId, walletAddress, txHash, metadata) {
    const html = `
        <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
            <h1>🎫 Your Ticket is Confirmed!</h1>
            
            <div style="background: #f5f5f5; padding: 20px; border-radius: 10px; margin: 20px 0;">
                <h2 style="margin-top: 0;">${metadata.name || `Ticket #${tokenId}`}</h2>
                
                ${metadata.image ? `<img src="${metadata.image.replace('ipfs://', 'https://ipfs.io/ipfs/')}" style="max-width: 100%; border-radius: 8px;" />` : ''}
                
                <p>${metadata.description || ''}</p>
            </div>
            
            <h3>📍 Event Details</h3>
            <table style="width: 100%; border-collapse: collapse;">
                ${metadata.attributes?.map(attr => `
                    <tr>
                        <td style="padding: 8px; border-bottom: 1px solid #eee;"><strong>${attr.trait_type}</strong></td>
                        <td style="padding: 8px; border-bottom: 1px solid #eee;">${attr.value}</td>
                    </tr>
                `).join('') || ''}
            </table>
            
            <h3>🔗 Blockchain Details</h3>
            <table style="width: 100%; border-collapse: collapse;">
                <tr>
                    <td style="padding: 8px; border-bottom: 1px solid #eee;"><strong>Token ID</strong></td>
                    <td style="padding: 8px; border-bottom: 1px solid #eee;">#${tokenId}</td>
                </tr>
                <tr>
                    <td style="padding: 8px; border-bottom: 1px solid #eee;"><strong>Your Wallet</strong></td>
                    <td style="padding: 8px; border-bottom: 1px solid #eee; font-size: 12px;">${walletAddress}</td>
                </tr>
                <tr>
                    <td style="padding: 8px; border-bottom: 1px solid #eee;"><strong>Transaction</strong></td>
                    <td style="padding: 8px; border-bottom: 1px solid #eee;">
                        <a href="https://sepolia.arbiscan.io/tx/${txHash}">View on Arbiscan</a>
                    </td>
                </tr>
            </table>
            
            <div style="background: #e8f4e8; padding: 15px; border-radius: 8px; margin-top: 20px;">
                <h4 style="margin-top: 0;">📱 View in MetaMask</h4>
                <ol style="margin-bottom: 0;">
                    <li>Open MetaMask → NFTs tab</li>
                    <li>Click "Import NFT"</li>
                    <li>Contract: <code>${process.env.NFT_CONTRACT}</code></li>
                    <li>Token ID: <code>${tokenId}</code></li>
                </ol>
            </div>
            
            <p style="color: #666; font-size: 12px; margin-top: 30px;">
                This ticket is stored on the blockchain and cannot be duplicated or forged.
            </p>
        </div>
    `;

    // console.log('📧 Calling Resend API...');

    // const result = await resend.emails.send({
    //     from: 'onboarding@resend.dev',
    //     to: buyerEmail,
    //     subject: `🎫 Your Ticket: ${metadata.name || `#${tokenId}`}`,
    //     html: html
    // });

    // console.log('📧 Resend response:', JSON.stringify(result, null, 2));

    // if (result.error) {
    //     console.error('📧 Email error:', result.error);
    // } else {
    //     console.log(`📧 Ticket email sent to ${buyerEmail}`);
    // }

    await resend.emails.send({
        from: 'onboarding@resend.dev',
        to: buyerEmail,
        subject: `🎫 Your Ticket: ${metadata.name || `#${tokenId}`}`,
        html: html
    });

    console.log(`📧 Ticket email sent to ${buyerEmail}`);
}

async function initWallet() {
    const provider = new ethers.JsonRpcProvider(process.env.RPC_URL);
    const keystorePath = process.env.KEYSTORE_PATH;
    const keystore = fs.readFileSync(keystorePath, 'utf8');

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

        const buyerEmail = session.customer_details?.email;  // ← Add this line!
        console.log('📧 Buyer email:', buyerEmail);

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
        console.log(`   Email: ${buyerEmail}`);
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

            // Fetch metadata and send email
            if (buyerEmail) {
                try {
                    const metadata = await getNFTMetadata(currentTokenId);
                    console.log('📄 Metadata:', metadata);
                    await sendTicketEmail(buyerEmail, currentTokenId, buyerWallet, tx.hash, metadata);
                } catch (emailErr) {
                    console.error('📧 Email error (non-fatal):', emailErr.message);
                    // Don't fail the whole transaction if email fails
                }
            }

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