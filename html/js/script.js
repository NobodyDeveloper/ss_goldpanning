const canvas = document.querySelector(".canvas");
const ctx = canvas.getContext("2d");
let goldChance = 0.5; // Default to 50% chance if not provided
let handlingGold = false; // Flag to prevent multiple gold spawns
let success = false;


canvas.width = window.innerWidth;
canvas.height = window.innerHeight;


const backgroundImage = new Image();
backgroundImage.src = "img/background.png";

const fullImage = new Image();
fullImage.src = "img/full.png";

const partialImages = [];
for (let i = 1; i <= 6; i++) {
    const img = new Image();
    img.src = `img/partial${i}.png`;
    partialImages.push(img);
}


const goldImage = new Image();
goldImage.src = "img/gold.png";

let goldPositions = []; 
let goldCollected = 0;


function spawnGold() {
    goldPositions = [];
    const goldCount = 1;

    for (let i = 0; i < goldCount; i++) {
        const offsetX = Math.random() * 100 - 50;
        const offsetY = Math.random() * 100 - 50;

        // Calculate gold positions relative to the center of the background image
        const goldX = backgroundImage.width / 2 + offsetX;
        const goldY = backgroundImage.height / 2 + offsetY;

        goldPositions.push({ x: goldX, y: goldY, clicked: false });
    }

    currentImage = null;
    drawImages(); // Redraw the canvas to include gold images
}

// Load the audio track
const dragAudio = new Audio("audio/shake.mp3");

let imageX, imageY;
let isDragging = false;
let offsetX, offsetY;
let totalDistance = 0;
const shakeThreshold = 25; // Number of shakes required
const shakeDistance = 150; // Distance per shake
let currentImage = fullImage;
let currentPartialIndex = 0;


function drawImages() {
 
    ctx.clearRect(0, 0, canvas.width, canvas.height);


    ctx.drawImage(backgroundImage, imageX, imageY);

 
    if (currentImage) {
        const fullX = imageX + (backgroundImage.width - currentImage.width) / 2;
        const fullY =
            imageY + (backgroundImage.height - currentImage.height) / 2;
        ctx.drawImage(currentImage, fullX, fullY);
    }

 
    goldPositions.forEach((gold) => {
        if (!gold.clicked) {
            const goldDrawX = imageX + gold.x - backgroundImage.width / 2;
            const goldDrawY = imageY + gold.y - backgroundImage.height / 2;
            ctx.drawImage(goldImage, goldDrawX + 150, goldDrawY + 140, 50, 50);
        }
    });
}


function initializeCanvas() {
    imageX = (canvas.width - backgroundImage.width) / 2;
    imageY = (canvas.height - backgroundImage.height) / 2;

    drawImages();
}


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


canvas.addEventListener("mousedown", (e) => {
    const rect = canvas.getBoundingClientRect();
    const mouseX = e.clientX - rect.left;
    const mouseY = e.clientY - rect.top;

 
    if (
        mouseX >= imageX &&
        mouseX <= imageX + backgroundImage.width &&
        mouseY >= imageY &&
        mouseY <= imageY + backgroundImage.height
    ) {
        isDragging = true;
        offsetX = mouseX - imageX;
        offsetY = mouseY - imageY;

      
        if (dragAudio.paused) {
            dragAudio.loop = true;
            dragAudio.play().catch((error) => {
                console.warn("Audio play interrupted:", error);

           
                dragAudio.pause();
                dragAudio.currentTime = 0;
                setTimeout(() => {
                    dragAudio.play().catch((retryError) => {
                        console.error("Retrying audio play failed:", retryError);
                    });
                }, 100);
            });
        }
    }
});


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
            gold.clicked = true; 
            goldCollected++;

       
            if (goldCollected === goldPositions.length) {
                console.log("All gold collected!");
            }

            drawImages();
        }
    });
});


canvas.addEventListener("mousemove", (e) => {
    if (isDragging) {
        const rect = canvas.getBoundingClientRect();
        const mouseX = e.clientX - rect.left;
        const mouseY = e.clientY - rect.top;

   
        const deltaX = mouseX - offsetX - imageX;
        const deltaY = mouseY - offsetY - imageY;
        const distance = Math.sqrt(deltaX ** 2 + deltaY ** 2);

  
        imageX = mouseX - offsetX;
        imageY = mouseY - offsetY;

        
        totalDistance += distance;

 
        if (totalDistance >= shakeThreshold * shakeDistance) {
            totalDistance = 0;


            if (currentImage === fullImage) {
                currentImage = partialImages[0];
                console.log("Switched to partial1");
            } else if (currentPartialIndex < partialImages.length - 1) {
                currentPartialIndex++;
                currentImage = partialImages[currentPartialIndex];
                console.log(
                    `Switched to partial${currentPartialIndex + 1}`
                );
            } else {
                currentImage = null; 
                if (!handlingGold) {
                handleGoldDisplay(); 
                success = true; 
                handlingGold = true;
                }
            }
        }

        // Redraw the images
        drawImages();
    }
});


canvas.addEventListener("mouseup", () => {
    isDragging = false;


    if (!dragAudio.paused) {
        dragAudio.pause();
        dragAudio.currentTime = 0;
    }
});


canvas.addEventListener("mouseout", () => {
    isDragging = false;


    if (!dragAudio.paused) {
        dragAudio.pause();
        dragAudio.currentTime = 0;
    }
});


window.addEventListener("message", (event) => {
    const data = event.data;


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

        if (
            typeof data.goldChance !== "number" ||
            data.goldChance < 0 ||
            data.goldChance > 1
        ) {
            console.warn("Invalid goldChance value:", data.goldChance);
            return; // Exit if goldChance is invalid
        }

        startSiftingMinigame(data.goldChance);
    }
});


function endMinigame(showedGold) {
    console.log("endMinigame called, hiding canvas...");
   
    ctx.clearRect(0, 0, canvas.width, canvas.height);

    goldPositions = [];
    goldCollected = 0;
    currentImage = null;
    currentPartialIndex = 0;
    totalDistance = 0;

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
    goldPositions = [];
    goldCollected = 0;
    currentImage = fullImage;
    currentPartialIndex = 0;
    totalDistance = 0;
    handlingGold = false; 
    drawImages(); 
}


function handleGoldDisplay() {
    const showedGold = Math.random() < goldChance;
    console.log("Gold displayed:", showedGold);

    if (showedGold) {
        spawnGold(); 
        setTimeout(() => {
            endMinigame(true); 
        }, 5000);
    } else {
        
        setTimeout(() => {
            endMinigame(showedGold);
        }, 5000);
    }
}

function startSiftingMinigame(goldChance) {

    canvas.style.display = "block";
    goldChance = goldChance;
    // Reset the game state
    resetGame();


    initializeCanvas();
}

window.addEventListener("keydown", (event) => {
    if (event.key === "Escape") {
        console.log("Escape key pressed. Ending minigame with no gold found.");

        // End the minigame and send the callback with no gold found
        endMinigame(false);
    }
});
