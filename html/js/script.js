const canvas = document.querySelector(".canvas");
const ctx = canvas.getContext("2d");
let goldChance = 0.5; // Default to 50% chance if not provided
let handlingGold = false; // Flag to prevent multiple gold spawns
let success = false; // Track if the minigame was successful

// Set canvas dimensions
canvas.width = window.innerWidth;
canvas.height = window.innerHeight;

// Load the background image
const backgroundImage = new Image();
backgroundImage.src = "img/background.png";

// Load the "full" image
const fullImage = new Image();
fullImage.src = "img/full.png";

// Load the "partial" images
const partialImages = [];
for (let i = 1; i <= 6; i++) {
    const img = new Image();
    img.src = `img/partial${i}.png`;
    partialImages.push(img);
}

// Load the gold image
const goldImage = new Image();
goldImage.src = "img/gold.png";

let goldPositions = []; // Store positions of gold images
let goldCollected = 0; // Track the number of gold images clicked

// Update the spawnGold function to spawn gold in the middle of the background
function spawnGold() {
    goldPositions = []; // Reset gold positions
    const goldCount = 1; // Number of gold images to spawn

    for (let i = 0; i < goldCount; i++) {
        const offsetX = Math.random() * 100 - 50; // Random offset between -50 and 50
        const offsetY = Math.random() * 100 - 50;

        // Calculate gold positions relative to the center of the background image
        const goldX = backgroundImage.width / 2 + offsetX;
        const goldY = backgroundImage.height / 2 + offsetY;

        goldPositions.push({ x: goldX, y: goldY, clicked: false });
    }

    currentImage = null; // Hide "partial6" by setting currentImage to null
    drawImages(); // Redraw the canvas to include gold images
}

// Load the audio track
const dragAudio = new Audio("audio/shake.mp3"); // Replace with your audio file path

let imageX, imageY; // Initial positions of the background image
let isDragging = false;
let offsetX, offsetY;
let totalDistance = 0; // Track the total distance moved
const shakeThreshold = 25; // Number of shakes required
const shakeDistance = 150; // Distance per shake
let currentImage = fullImage; // Start with the "full" image
let currentPartialIndex = 0; // Track the current partial image index

// Update the drawImages function to account for the background's position
function drawImages() {
    // Clear the canvas
    ctx.clearRect(0, 0, canvas.width, canvas.height);

    // Draw the background image
    ctx.drawImage(backgroundImage, imageX, imageY);

    // Draw the current image if it exists
    if (currentImage) {
        const fullX = imageX + (backgroundImage.width - currentImage.width) / 2;
        const fullY =
            imageY + (backgroundImage.height - currentImage.height) / 2;
        ctx.drawImage(currentImage, fullX, fullY);
    }

    // Draw gold images relative to the background's position
    goldPositions.forEach((gold) => {
        if (!gold.clicked) {
            const goldDrawX = imageX + gold.x - backgroundImage.width / 2;
            const goldDrawY = imageY + gold.y - backgroundImage.height / 2;
            ctx.drawImage(goldImage, goldDrawX + 150, goldDrawY + 140, 50, 50); // Draw gold with a fixed size
        }
    });
}

// Center the background image on the canvas when both images are loaded
function initializeCanvas() {
    imageX = (canvas.width - backgroundImage.width) / 2;
    imageY = (canvas.height - backgroundImage.height) / 2;

    drawImages();
}

// Ensure all images are loaded before initializing the canvas
backgroundImage.onload = () => {
    if (fullImage.complete) {
        initializeCanvas();
    }
};

fullImage.onload = () => {
    if (backgroundImage.complete) {
        initializeCanvas();
    }
};

// Handle mouse down event
canvas.addEventListener("mousedown", (e) => {
    const rect = canvas.getBoundingClientRect();
    const mouseX = e.clientX - rect.left;
    const mouseY = e.clientY - rect.top;

    // Check if the mouse is over the background image
    if (
        mouseX >= imageX &&
        mouseX <= imageX + backgroundImage.width &&
        mouseY >= imageY &&
        mouseY <= imageY + backgroundImage.height
    ) {
        isDragging = true;
        offsetX = mouseX - imageX;
        offsetY = mouseY - imageY;

        // Play the audio only if it's not already playing
        if (dragAudio.paused) {
            dragAudio.loop = true; // Ensure the audio loops while dragging
            dragAudio.play().catch((error) => {
                console.warn("Audio play interrupted:", error);

                // Pause and reset the audio, then attempt to play it again
                dragAudio.pause();
                dragAudio.currentTime = 0; // Reset the audio to the beginning
                setTimeout(() => {
                    dragAudio.play().catch((retryError) => {
                        console.error("Retrying audio play failed:", retryError);
                    });
                }, 100); // Retry after a short delay
            });
        }
    }
});

// Add click event listener for gold images
canvas.addEventListener("click", (e) => {
    const rect = canvas.getBoundingClientRect();
    const mouseX = e.clientX - rect.left;
    const mouseY = e.clientY - rect.top;

    goldPositions.forEach((gold) => {
        if (
            !gold.clicked &&
            mouseX >= imageX + gold.x - backgroundImage.width / 2 &&
            mouseX <= imageX + gold.x - backgroundImage.width / 2 + 50 &&
            mouseY >= imageY + gold.y - backgroundImage.height / 2 &&
            mouseY <= imageY + gold.y - backgroundImage.height / 2 + 50
        ) {
            gold.clicked = true; // Mark gold as clicked
            goldCollected++;

            // Check if all gold is collected
            if (goldCollected === goldPositions.length) {
                console.log("All gold collected!");
            }

            drawImages(); // Redraw the canvas to hide the clicked gold
        }
    });
});

// Update the mousemove event to handle the last partial image
canvas.addEventListener("mousemove", (e) => {
    if (isDragging) {
        const rect = canvas.getBoundingClientRect();
        const mouseX = e.clientX - rect.left;
        const mouseY = e.clientY - rect.top;

        // Calculate the distance moved
        const deltaX = mouseX - offsetX - imageX;
        const deltaY = mouseY - offsetY - imageY;
        const distance = Math.sqrt(deltaX ** 2 + deltaY ** 2);

        // Update background image position
        imageX = mouseX - offsetX;
        imageY = mouseY - offsetY;

        // Update the total distance moved
        totalDistance += distance;

        // Check if the shake threshold is met
        if (totalDistance >= shakeThreshold * shakeDistance) {
            totalDistance = 0; // Reset the total distance

            // Switch to the next partial image
            if (currentImage === fullImage) {
                currentImage = partialImages[0]; // Start with partial1
                console.log("Switched to partial1");
            } else if (currentPartialIndex < partialImages.length - 1) {
                currentPartialIndex++;
                currentImage = partialImages[currentPartialIndex];
                console.log(
                    `Switched to partial${currentPartialIndex + 1}`
                );
            } else {
                currentImage = null; // Hide "partial6"
                if (!handlingGold) {
                handleGoldDisplay(); // Show gold
                success = true; // Set success to true
                handlingGold = true; // Prevent multiple gold spawns
                }
            }
        }

        // Redraw the images
        drawImages();
    }
});

// Handle mouse up event
canvas.addEventListener("mouseup", () => {
    isDragging = false;

    // Pause the audio only if it's playing
    if (!dragAudio.paused) {
        dragAudio.pause();
        dragAudio.currentTime = 0; // Reset the audio to the beginning
    }
});

// Handle mouse out event (stop dragging if the mouse leaves the canvas)
canvas.addEventListener("mouseout", () => {
    isDragging = false;

    // Pause the audio only if it's playing
    if (!dragAudio.paused) {
        dragAudio.pause();
        dragAudio.currentTime = 0; // Reset the audio to the beginning
    }
});

// Listen for NUI messages
window.addEventListener("message", (event) => {
    const data = event.data;

    // Security check: Validate the incoming data
    if (
        typeof data !== "object" ||
        !data.action ||
        typeof data.action !== "string"
    ) {
        console.warn("Invalid message received:", data);
        return; // Exit if the data is invalid
    }

    if (data.action === "startSiftingMinigame") {
        console.log(
            "Starting sifting minigame with gold chance:",
            data.goldChance
        );

        // Validate goldChance to ensure it's a number between 0 and 1
        if (
            typeof data.goldChance !== "number" ||
            data.goldChance < 0 ||
            data.goldChance > 1
        ) {
            console.warn("Invalid goldChance value:", data.goldChance);
            return; // Exit if goldChance is invalid
        }

        // Start the minigame logic here
        startSiftingMinigame(data.goldChance);
    }
});

// Function to handle the end of the minigame
function endMinigame(showedGold) {
    console.log("endMinigame called, hiding canvas...");
    // Clear the canvas to remove all images
    ctx.clearRect(0, 0, canvas.width, canvas.height);

    // Reset game state
    goldPositions = [];
    goldCollected = 0;
    currentImage = null;
    currentPartialIndex = 0;
    totalDistance = 0;

    // Hide the canvas and reset its dimensions
    canvas.style.display = "none";

    // Send the NUI callback with the result
    fetch(`https://${GetParentResourceName()}/minigameResult`, {
        method: "POST",
        headers: {
            "Content-Type": "application/json",
        },
        body: JSON.stringify({
            success: success,
            showedGold: showedGold,
        }),
    });
}

// Function to reset the game
function resetGame() {
    console.log("Resetting the game...");
    goldPositions = []; // Clear gold positions
    goldCollected = 0; // Reset collected gold count
    currentImage = fullImage; // Reset to the full image
    currentPartialIndex = 0; // Reset partial image index
    totalDistance = 0; // Reset shake distance
    handlingGold = false; // Reset the gold handling flag
    drawImages(); // Redraw the canvas
}

// Function to handle the gold display logic
function handleGoldDisplay() {
    const showedGold = Math.random() < goldChance; // Determine if gold is shown
    console.log("Gold displayed:", showedGold);

    if (showedGold) {
        spawnGold(); // Spawn gold images and handle the callback
        setTimeout(() => {
            endMinigame(true); // End the minigame after 5 seconds
        }, 5000);
    } else {
        // If no gold is shown, end the minigame after 5 seconds
        setTimeout(() => {
            endMinigame(showedGold);
        }, 5000);
    }
}

function startSiftingMinigame(goldChance) {
    // Display the canvas
    canvas.style.display = "block";
    goldChance = goldChance; // Default to 50% chance if not provided
    // Reset the game state
    resetGame();

    // Initialize the canvas
    initializeCanvas();
}

window.addEventListener("keydown", (event) => {
    if (event.key === "Escape") {
        console.log("Escape key pressed. Ending minigame with no gold found.");

        // End the minigame and send the callback with no gold found
        endMinigame(false);
    }
});
