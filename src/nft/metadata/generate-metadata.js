// generate-metadata.js
// 
// SETUP ORDER:
// 1. Create ONE ticket image (ticket.png)
// 2. Upload image to Pinata → get IMAGE_CID
// 3. Update IMAGE_CID below
// 4. Run: node generate-metadata.js
// 5. Upload 'metadata' folder to Pinata → get METADATA_CID
// ============================================
// METADATA_CID: bafybeietec3bj25jax2r73xtyiqvwgpouppkns4s76dndxbnj4dusx6dka
// ============================================
// 6. Deploy contract with baseURI = "ipfs://bafybeietec3bj25jax2r73xtyiqvwgpouppkns4s76dndxbnj4dusx6dka/" ["ipfs://METADATA_CID/"]

const fs = require('fs');
const path = require('path');

// ============================================
// CONFIGURATION - UPDATE THESE VALUES
// ============================================

// After uploading your ticket image to Pinata, paste the CID here:
const IMAGE_CID = "bafkreigusj7a357qunh2balemajtab5ksoq2fssqu3qryh7la7w3xolgjq"; // e.g., "QmX7b5jxn6Vp2HS4Y3..."

// Event details
const EVENT = {
    name: "Champions League Final 2026",
    date: "May 30, 2026",
    time: "21:00 CET",
    venue: "Allianz Arena, Munich"
};

const TOTAL_TICKETS = 100;

// ============================================
// GENERATE METADATA
// ============================================

// Validate IMAGE_CID is set
if (IMAGE_CID === "YOUR_IMAGE_CID_HERE") {
    console.log("❌ ERROR: Please update IMAGE_CID first!\n");
    console.log("Steps:");
    console.log("1. Create a ticket image (e.g., ticket.svg)");
    console.log("2. Upload to Pinata (https://app.pinata.cloud)");
    console.log("3. Copy the CID");
    console.log("4. Paste it in this script as IMAGE_CID");
    console.log("5. Run this script again\n");
    process.exit(1);
}

// Create metadata directory
const metadataDir = path.join(__dirname, 'metadata');
if (!fs.existsSync(metadataDir)) {
    fs.mkdirSync(metadataDir, { recursive: true });
}

// Single image URI for ALL tickets
const imageURI = `ipfs://${IMAGE_CID}`;

// Generate metadata for each ticket
for (let tokenId = 1; tokenId <= TOTAL_TICKETS; tokenId++) {
    const metadata = {
        name: `${EVENT.name} - Ticket #${tokenId}`,
        description: `Official match ticket for ${EVENT.name} at ${EVENT.venue}.`,
        image: imageURI,
        attributes: [
            { trait_type: "Event", value: EVENT.name },
            { trait_type: "Date", value: EVENT.date },
            { trait_type: "Time", value: EVENT.time },
            { trait_type: "Venue", value: EVENT.venue }
        ]
    };

    // Write file WITHOUT extension (OpenSea/marketplace standard)
    const filePath = path.join(metadataDir, tokenId.toString());
    fs.writeFileSync(filePath, JSON.stringify(metadata, null, 2));
}

console.log(`\n✅ Generated ${TOTAL_TICKETS} metadata files in ./metadata/\n`);
console.log(`All tickets use image: ${imageURI}\n`);
console.log("Next steps:");
console.log("1. Upload the 'metadata' folder to Pinata");
console.log("2. Copy the METADATA_CID");
console.log("3. Deploy contract with:");
console.log(`   baseURI = "ipfs://YOUR_METADATA_CID/"\n`);
console.log("Example deployment:");
console.log(`   new PlatformNFT(ownerAddress, "ipfs://YOUR_METADATA_CID/")\n`);