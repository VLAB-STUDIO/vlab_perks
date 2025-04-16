let lastSkillsData = [];
let acquiredPerks = [];
let uiVisible = false;
let viewMode = "skills";
window.redeemedRewards = [];

window.addEventListener('message', function(event) {
    if (event.data.type === "toggleUI") {
        if (event.data.status) {
            const openSound = new Audio('sound/open.mp3');
            openSound.volume = 0.2;
            openSound.play().catch(err => console.warn("Errore suono apertura:", err));
            document.getElementById("perk-container").classList.remove("hidden");
            var topBox = document.getElementById("top-box");
            if (topBox) {
                topBox.style.display = "block";
            }
            if (event.data.skills) {
                lastSkillsData = event.data.skills;
                viewMode = "skills";
                populateSkills(lastSkillsData);
            }
            if (event.data.discordAvatar) {
                document.getElementById("discord-avatar").src = event.data.discordAvatar;
            }
            document.getElementById("player-name").textContent = event.data.playerFirstName + " " + event.data.playerLastName;
            document.getElementById("player-job").textContent = event.data.playerJob;
            document.getElementById("player-age").textContent = "Points: " + event.data.playerAge;
        } else {
            document.getElementById("perk-container").classList.add("hidden");
        }
    }
    else if (event.data.type === "receiveConfig") {
        window.Config = {
            Perks: event.data.perks,
            Skills: event.data.skills
        };
    }
    else if (event.data.type === "acquirePerkResult") {
        if (event.data.success) {
        } else {
        }
    }
    else if (event.data.type === "updatePoints") {
        document.getElementById("player-age").textContent = "Points: " + event.data.playerAge;
    }
    else if (event.data.type === "acquiredPerks") {
        acquiredPerks = event.data.acquiredPerks;
        markAcquiredPerks();
        if (viewMode === "perks") {
            changePage("perks");
        }
    }
    else if (event.data.type === "updateRedeemedRewards") {
        if (event.data.redeemedRewards && event.data.redeemedRewards.length > 0) {
            event.data.redeemedRewards.forEach(function(key) {
                if (!window.redeemedRewards.includes(key)) {
                    window.redeemedRewards.push(key);
                }
            });
        } else {
        }
        if (viewMode === "skills" && lastSkillsData && lastSkillsData.length > 0) {
            populateSkills(lastSkillsData);
        }
    }
});

window.addEventListener('message', function(event) {
    if (event.data.type === "sendSkills") {
        lastSkillsData = event.data.skills;
        viewMode = "skills";
        populateSkills(lastSkillsData);
        if (typeof SendNUIMessage !== "undefined") {
            SendNUIMessage({
                type: "sendSkills",
                skills: event.data.skills
            });
        }
    }
});

const topBox = document.getElementById("top-box");
if (topBox) {
    topBox.addEventListener("click", function () {
        const clickSound = new Audio('sound/select.mp3');
        clickSound.volume = 0.5;
        clickSound.play().catch(err => console.warn("Errore suono click top-box:", err));

        viewMode = "perks";
        changePage("perks");
    });

    topBox.addEventListener("mouseenter", function () {
        const hoverSound = new Audio('sound/hover.mp3');
        hoverSound.volume = 0.03;
        hoverSound.play().catch(err => console.warn("Errore suono hover top-box:", err));
    });
}

document.getElementById("perk-content").addEventListener("click", function(e) {
    let card = e.target.closest(".perk-card");
    if (card) {
        let skillData = card.getAttribute('data-skill');
        if (skillData) {
            try {
                let skill = JSON.parse(decodeURIComponent(skillData));
                openSkillInterface(skill);
            } catch (err) {
            }
        } else {
            let perkData = card.getAttribute('data-perk');
            try {
                let perk = JSON.parse(decodeURIComponent(perkData));
                open3DCard(perk);
            } catch (err) {
            }
        }
    }
});

function markAcquiredPerks() {
    const perkCards = document.querySelectorAll(".perk-card");
    perkCards.forEach(card => {
        try {
            let perkData = JSON.parse(decodeURIComponent(card.getAttribute('data-perk')));
            if (acquiredPerks.includes(perkData.funcs)) {
                card.classList.add("acquired");
            }
        } catch (err) {
        }
    });
}

function changePage(page) {
    if (page === "skills") {
        if (lastSkillsData && Array.isArray(lastSkillsData)) {
            populateSkills(lastSkillsData);
        } else {
        }
    }

    else if (page === "perks") {
        if (window.Config && Array.isArray(window.Config.Perks)) {
            let perksHTML = window.Config.Perks.map(perk => {
                let isAcquired = acquiredPerks.includes(perk.funcs);
                let iconPath = isAcquired ? `img/${perk.icon}.png` : "img/ability_card.png";
                let acquiredClass = isAcquired ? 'acquired' : '';
                return `
                    <div class="perk-card ${acquiredClass}" data-perk="${encodeURIComponent(JSON.stringify(perk))}">
                        <img src="${iconPath}" alt="${perk.label}">
                        <h3>${perk.label}</h3>
                        <p>${perk.desc}</p>
                    </div>
                `;
            }).join('');
            document.getElementById("perk-content").innerHTML = `
                <div class="main-perks-page">
                    <h2></h2>
                    <div class="perks-cards-wrapper">
                        <div class="perks-cards-container">
                            ${perksHTML}
                        </div>
                    </div>
                </div>
                <button class="back-button" onclick="goBack()">
                    <img src="img/back.png" alt="Torna indietro">
                </button>
            `;
            setTimeout(() => {
                document.querySelectorAll(".perk-card").forEach(card => {
                    card.addEventListener("mouseenter", () => {
                        const hoverSound = new Audio('sound/hover.mp3');
                        hoverSound.volume = 0.03;
                        hoverSound.play().catch(err => console.warn("Errore suono hover perk:", err));
                    });
                });
            }, 50);
        } else {
        }
    }
}

function openMainUI() {
    var container = document.getElementById("perk-container");
    container.classList.remove("hidden");
    var topBox = document.getElementById("top-box");
    if (topBox) {
        topBox.style.display = "block";
        topBox.style.visibility = "visible";
        topBox.style.opacity = "1";
        topBox.classList.remove("hidden");
    } else {
    }
    var content = document.getElementById("perk-content");
    if (lastSkillsData && lastSkillsData.length > 0) {
        populateSkills(lastSkillsData);
    } else {
        content.innerHTML = `<p>Contenuto iniziale</p>`;
    }
}

function populateSkills(skills) {
    let container = document.getElementById("perk-content");
    container.innerHTML = "";
    skills.forEach(skill => {
        let box = document.createElement("div");
        box.className = "perk-box";
        box.setAttribute("data-skill", encodeURIComponent(JSON.stringify(skill)));
        let img = document.createElement("img");
        img.src = `img/${skill.skillName}.png`;
        img.alt = skill.skillLabel;
        let label = document.createElement("span");
        label.textContent = skill.skillLabel;
        box.appendChild(img);
        box.appendChild(label);
        container.appendChild(box);
        box.addEventListener("click", function() {
            const skillClickSound = new Audio('sound/select.mp3');
            skillClickSound.volume = 0.5;
            skillClickSound.play().catch(err => console.warn("Errore suono click skill:", err));
            openSkillInterface(skill);
        });
        box.addEventListener("mouseenter", function () {
            const hoverSound = new Audio('sound/hover.mp3');
            hoverSound.volume = 0.03;
            hoverSound.play().catch(err => console.warn("Errore suono hover skill:", err));
        });
    });
}

function getSkillLevelLabel(level) {
    if (level < 2) {
        return "Novice";
    } else if (level < 4) {
        return "Beginner";
    } else if (level < 6) {
        return "Skilled";
    } else if (level < 8) {
        return "Advanced";
    } else {
        return "Expert";
    }
}

function openMainUI() {
    const container = document.getElementById("perk-container");
    if (container) {
        container.classList.remove("hidden");
    }
    const topBox = document.getElementById("top-box");
    if (topBox) {
        topBox.style.display = "block";
        topBox.style.visibility = "visible";
        topBox.style.opacity = "1";
        topBox.classList.remove("hidden");
    } else {
    }
    const content = document.getElementById("perk-content");
    if (lastSkillsData && lastSkillsData.length > 0) {
        populateSkills(lastSkillsData);
    } else {
        content.innerHTML = `<p>Contenuto iniziale</p>`;
    }
}

function redeemReward({ label, amount, rewardName, RewardLabel, squareId, skillKey, rewardLevel, rewardType }) {
    skillKey = skillKey || "unknown";
    rewardLevel = rewardLevel || 0;
    let square = document.getElementById(squareId);
    if (!square) {
        return;
    }
    let originalSquare = square.cloneNode(true);
    const redeemButton = document.querySelector("#reward-detail .redeem-button");
    if (redeemButton) {
        redeemButton.disabled = true;
    } else {
    }
    fetch(`https://${GetParentResourceName()}/redeemReward`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json; charset=UTF-8',
        },
        body: JSON.stringify({
            rewardName,
            RewardLabel,
            amount,
            skillKey,
            rewardLevel,
            rewardType
        })
    })    
    .then((resp) => {
        return resp.json();
    })
    .then((data) => {
        if (data.status === "ok" && (!data.message || !data.message.toLowerCase().includes("inventario pieno"))) {
            if (square) {
                square.innerHTML = `
                    <img src="img/toast_mp_reward_rockstar.png" alt="${RewardLabel}" title="${RewardLabel}">
                    <div class="watermark"></div>
                `;
                square.style.pointerEvents = "none";
                const rewardKey = `${skillKey}:${parseInt(rewardLevel)}`;
                if (!window.redeemedRewards.includes(rewardKey)) {
                    window.redeemedRewards.push(rewardKey);
                }
            } else {
            }
            document.getElementById("reward-detail").innerHTML = "";
            document.getElementById("reward-detail").classList.add("hidden");
            openMainUI();
            setTimeout(() => {
                const rewardKey = `${skillKey}:${parseInt(rewardLevel)}`;
                if (!window.redeemedRewards.includes(rewardKey)) {
                    square.replaceWith(originalSquare);
                } else {
                }
            }, 3000);
        } else {
            square.replaceWith(originalSquare);
            if (redeemButton) {
                redeemButton.disabled = false;
            }
        }
    })
    .catch((error) => {
        square.replaceWith(originalSquare);
        if (redeemButton) {
            redeemButton.disabled = false;
        }
    });
}

function showRewardDetail(label, amount, rewardName, RewardLabel, squareId, skillKey, rewardLevel, rewardType) {
    const detail = document.getElementById("reward-detail");
    detail.innerHTML = `
        <p style="color: white; font-family: 'Milonga', cursive; font-size: 18px;">
            <strong></strong> ${label}<br>
            <strong>Amount:</strong> ${amount}
        </p>
        <button class="redeem-button" id="redeem-btn">
            REDEEM
        </button>
    `;
    detail.classList.remove("hidden");
    const redeemButton = document.getElementById("redeem-btn");
    redeemButton.addEventListener('click', function() {
         redeemButton.disabled = true;
         redeemReward({
            label,
            amount,
            rewardName,
            RewardLabel,
            squareId,
            skillKey,
            rewardLevel,
            rewardType
        });      
    });
}

function openSkillInterface(skill) {
    let level = skill.Level || 1;
    let exp = skill.Exp || 0;
    let skillName = skill.skillLabel || "Skill";
    let skillKey = (skill.skillName && skill.skillName.trim() !== "") ? skill.skillName : "unknown";
    let skillImage = `img/${skillKey}.png`;
    let requiredExp = level * 100;
    let progressPercent = Math.min((exp / requiredExp) * 100, 100);
    const skillConfig = window.Config.Skills?.find(s => s.skillName === skillKey);
    if (!skillConfig) {
        return;
    }
    const currentLevelData = skillConfig[level];
    const levelLabel = currentLevelData && currentLevelData.label ? currentLevelData.label : "Unknown";
    let squaresHTML = "";
    for (let i = 1; i <= 10; i++) {
        const reward = skillConfig[i];
        let rewardLabel = reward?.RewardLabel || `Slot ${i}`;
        let rewardAmount = reward?.amount || "0";
        if (i > level) {
            squaresHTML += `
                <div class="skill-square locked" data-label="${rewardLabel}" data-amount="${rewardAmount}">
                    <img src="img/toast_mp_reward_event.png" alt="${rewardLabel}" title="${rewardLabel}">
                    <div class="watermark"></div>
                </div>
            `;
        } else {
            let squareId = `reward-square-${skillKey}-${i}`;
            let isRedeemed = window.redeemedRewards && window.redeemedRewards.includes(skillKey + ":" + i);
            if (isRedeemed) {
                squaresHTML += `
                    <div id="${squareId}" class="skill-square redeemed" data-label="${rewardLabel}" data-amount="${rewardAmount}">
                        <img src="img/toast_mp_reward_rockstar.png" alt="${rewardLabel}" title="${rewardLabel}">
                        <div class="watermark"></div>
                    </div>
                `;
            } else {
                let imgSrc = "img/placeholder.png";
                if (reward && (reward.rewardType === "item" || reward.rewardType === "weapon") && reward.rewardName) {
                    imgSrc = `https://cfx-nui-vorp_inventory/html/img/items/${reward.rewardName}.png`;
                }
                squaresHTML += `
                    <div id="${squareId}" class="skill-square" data-label="${rewardLabel}" data-amount="${rewardAmount}"
                        onclick="showRewardDetail('${rewardLabel}', '${rewardAmount}', '${reward.rewardName}', '${reward.RewardLabel}', '${squareId}', '${skillKey}', ${i}, '${reward.rewardType}')">
                        <img src="${imgSrc}" alt="${rewardLabel}" title="${rewardLabel}">
                    </div>
                `;
            }
        }
    }

    document.getElementById("perk-content").innerHTML = `
        <div class="main-perks-page skill-interface">
            <div class="skill-image-wrapper">
                <img src="${skillImage}" alt="${skillName}" class="skill-full-image">
                <h2>${skillName}</h2>
            </div>
            <div class="progress-container" data-percent="${progressPercent.toFixed(2)}">
                <div class="progress-bar-inner" style="width: ${progressPercent}%;"></div>
            </div>
            <p class="progress-level">Level: ${level} - ${levelLabel}</p>
            <div class="skill-squares-wrapper">
                ${squaresHTML}
            </div>
            <div id="reward-detail" class="reward-detail hidden"></div>
        </div>
        <button class="back-button" onclick="goBack()">
            <img src="img/back.png" alt="Torna indietro">
        </button>
    `;

    setTimeout(() => {
        const squares = document.querySelectorAll(".skill-square:not(.locked):not(.redeemed)");
        squares.forEach(square => {
            square.addEventListener("mouseenter", () => {
                const hoverSound = new Audio('sound/hover.mp3');
                hoverSound.volume = 0.03;
                hoverSound.play().catch(err => console.warn("Hover square sound error:", err));
            });
            square.addEventListener("click", () => {
                const clickSound = new Audio('sound/select.mp3');
                clickSound.volume = 0.3;
                clickSound.play().catch(err => console.warn("Click square sound error:", err));
            });
        });
    }, 50);
}

function goBack() {
    const backSound = new Audio('sound/back.mp3');
    backSound.volume = 0.5;
    backSound.play().catch(err => console.warn("Sound error go back:", err));

    const topBox = document.getElementById("top-box");
    if (topBox) {
        topBox.style.display = "block";
        topBox.classList.remove("hidden");
    } else {
    }
    if (lastSkillsData && lastSkillsData.length > 0) {
        populateSkills(lastSkillsData);
    } else {
        document.getElementById("perk-content").innerHTML = `<p>Initial content</p>`;
    }
}

function closeUI() {
    fetch(`https://${GetParentResourceName()}/close`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({})
    });
}

function open3DCard(perk) {
    const open3DSound = new Audio('sound/open3d.mp3');
    open3DSound.volume = 0.8;
    open3DSound.play().catch(err => console.warn("3D opening sound error:", err));
    let modal = document.createElement('div');
    modal.id = "perk-modal";
    let isAcquired = acquiredPerks.includes(perk.funcs);
    let overlayHTML = "";
    if (!isAcquired) {
        overlayHTML = `
            <div id="acquire-overlay">
                <span class="acquire-text">HOLD TO ACQUIRE<br><br>
                    <strong style="color: #FFD700;">${perk.point}</strong> <span style="color: #ffffff;">POINTS</span>
                    <br><br>
                    <strong style="color: #FFD700;">${perk.money}</strong> <span style="color: #ffffff;">DOLLARS</span>
                </span>
                <div class="progress-bar"></div>
            </div>
        `;
    }
    modal.innerHTML = `
        <div class="perk-card-modal">
            ${overlayHTML}
            <button class="close-modal" onclick="close3DCard()"></button>
            <img src="img/${perk.icon}.png" alt="${perk.label}">
            <h3>${perk.label}</h3>
            <p>${perk.desc}</p>
        </div>
    `;
    document.body.appendChild(modal);
    setTimeout(() => {
        modal.classList.add('active');
    }, 10);
    const cardModal = modal.querySelector('.perk-card-modal');
    cardModal.addEventListener("mousemove", function(e) {
        const rect = cardModal.getBoundingClientRect();
        const centerX = rect.left + rect.width / 2;
        const centerY = rect.top + rect.height / 2;
        const deltaX = e.clientX - centerX;
        const deltaY = e.clientY - centerY;
        const rotationFactor = 20;
        const rotateX = -deltaY / rotationFactor;
        const rotateY = deltaX / rotationFactor;
        cardModal.style.transform = `rotateX(${rotateX}deg) rotateY(${rotateY}deg)`;
    });
    cardModal.addEventListener("mouseleave", function() {
        cardModal.style.transform = "rotateX(0deg) rotateY(0deg)";
    });
    if (!isAcquired) {
        let overlay = modal.querySelector('#acquire-overlay');
        let intervalId = null;
        let holdSound = null;
        overlay.addEventListener('mousedown', function(e) {
            e.preventDefault();
            holdSound = new Audio('sound/acquire.mp3');
            holdSound.loop = true;
            holdSound.play();
            let startTime = Date.now();
            intervalId = setInterval(function() {
                let elapsed = Date.now() - startTime;
                let progress = Math.min(elapsed / 1800, 1);
                overlay.querySelector('.progress-bar').style.height = (progress * 100) + "%";
                overlay.style.background = `rgba(0, 0, 0, ${0.8 * (1 - progress)})`;
                if (progress === 1) {
                    clearInterval(intervalId);
                    if (holdSound) {
                        holdSound.pause();
                        holdSound.currentTime = 0;
                    }
                    acquirePerk(perk.funcs, perk.point);
                    close3DCard();
                }
            }, 100);
        });
        
        function cancelHold() {
            clearInterval(intervalId);
            let progressBar = overlay.querySelector('.progress-bar');
            if (progressBar) {
                progressBar.style.height = "0%";
            }
            overlay.style.background = "rgba(0, 0, 0, 0.8)";
            if (holdSound) {
                holdSound.pause();
                holdSound.currentTime = 0;
            }
        }
        overlay.addEventListener('mouseup', cancelHold);
        overlay.addEventListener('mouseleave', cancelHold);
    }
}

function acquirePerk(funcName, cost) {
    fetch(`https://${GetParentResourceName()}/acquirePerk`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ funcName: funcName, cost: cost })
    }).then((resp) => resp.json()).then((data) => {
    });
    close3DCard();
}

function close3DCard() {
    const close3DSound = new Audio('sound/back.mp3');
    close3DSound.volume = 0.4;
    close3DSound.play().catch(err => console.warn("3D closing sound error:", err));
    let modal = document.getElementById("perk-modal");
    if (modal) {
        modal.classList.remove('active');
        setTimeout(() => {
            modal.remove();
        }, 300);
    }
}

function closeUI() {
    const audio = new Audio('sound/close.mp3');
    audio.volume = 0.2;
    audio.play().catch(err => console.warn("Audio playback errore:", err));
    fetch(`https://${GetParentResourceName()}/close`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({})
    });
}