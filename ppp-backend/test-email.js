// test-email.js
require('dotenv').config();
const { Resend } = require('resend');

const resend = new Resend(process.env.RESEND_API_KEY);

// Sample metadata (like what you'd get from IPFS)
const mockMetadata = {
    name: "Champions League Final 2026 - Seat A42",
    description: "Official match ticket",
    image: "ipfs://QmTest/1.png",
    attributes: [
        { trait_type: "Event", value: "Champions League Final 2026" },
        { trait_type: "Venue", value: "Wembley Stadium, London" },
        { trait_type: "Date", value: "May 30, 2026" },
        { trait_type: "Time", value: "20:00 GMT" },
        { trait_type: "Section", value: "A" },
        { trait_type: "Seat", value: "42" }
    ]
};

async function testEmail() {
    const tokenId = 1;
    const walletAddress = "0x7f44D3252A7a2C6FB0572e43C2A51e7204Bf7859";
    const txHash = "0xabc123fake456hash";
    const buyerEmail = "mihai.hanga@gmail.com";  // ← Change to your email!

    const html = `
        <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
            <h1>🎫 Your Ticket is Confirmed!</h1>
            
            <div style="background: #f5f5f5; padding: 20px; border-radius: 10px; margin: 20px 0;">
                <h2 style="margin-top: 0;">${mockMetadata.name}</h2>
                <p>${mockMetadata.description}</p>
            </div>
            
            <h3>📍 Event Details</h3>
            <table style="width: 100%; border-collapse: collapse;">
                ${mockMetadata.attributes.map(attr => `
                    <tr>
                        <td style="padding: 8px; border-bottom: 1px solid #eee;"><strong>${attr.trait_type}</strong></td>
                        <td style="padding: 8px; border-bottom: 1px solid #eee;">${attr.value}</td>
                    </tr>
                `).join('')}
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
        </div>
    `;

    try {
        const result = await resend.emails.send({
            from: 'onboarding@resend.dev',  // Resend test domain
            to: buyerEmail,
            subject: `🎫 Your Ticket: ${mockMetadata.name}`,
            html: html
        });

        console.log('✅ Email sent successfully!');
        console.log('   Result:', result);
    } catch (error) {
        console.error('❌ Email failed:', error);
    }
}

testEmail();