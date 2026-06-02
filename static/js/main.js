/* ==========================================================================
   Parking Lot Management System - Premium Javascript Core
   Description: Handles responsive navigations, active menus, live rosters searching,
                alert close actions, and real-time checkout fee estimation logic.
   ========================================================================== */

document.addEventListener("DOMContentLoaded", () => {
    // 1. Mobile Responsive Sidebar Toggle Action
    const sidebar = document.querySelector(".sidebar");
    const mobileToggle = document.querySelector(".mobile-nav-toggle");
    
    if (mobileToggle && sidebar) {
        mobileToggle.addEventListener("click", (e) => {
            e.stopPropagation();
            sidebar.classList.toggle("open");
        });
        
        // Close sidebar when clicking outside of it on mobile view
        document.addEventListener("click", (e) => {
            if (sidebar.classList.contains("open") && !sidebar.contains(e.target) && e.target !== mobileToggle) {
                sidebar.classList.remove("open");
            }
        });
    }

    // 2. Automatically Close Flash Alerts after 5 Seconds
    const alerts = document.querySelectorAll(".alert");
    alerts.forEach((alert) => {
        const closeBtn = alert.querySelector(".alert-close");
        if (closeBtn) {
            closeBtn.addEventListener("click", () => {
                alert.style.transition = "opacity 0.4s ease, transform 0.4s ease";
                alert.style.opacity = "0";
                alert.style.transform = "translateX(50px)";
                setTimeout(() => alert.remove(), 400);
            });
        }
        
        // Auto dismiss timer
        setTimeout(() => {
            if (alert.parentNode) {
                alert.style.transition = "opacity 0.5s ease, transform 0.5s ease";
                alert.style.opacity = "0";
                alert.style.transform = "translateX(50px)";
                setTimeout(() => alert.remove(), 500);
            }
        }, 6000);
    });

    // 3. Roster Live Searching Filter (Used in parked.html and exits)
    const searchInput = document.getElementById("roster-search");
    if (searchInput) {
        searchInput.addEventListener("input", (e) => {
            const filterValue = e.target.value.toLowerCase().strip ? e.target.value.toLowerCase().trim() : e.target.value.toLowerCase();
            const tableRows = document.querySelectorAll(".premium-table tbody tr");
            
            tableRows.forEach((row) => {
                const textContent = row.textContent.toLowerCase();
                if (textContent.includes(filterValue)) {
                    row.style.display = "";
                } else {
                    row.style.display = "none";
                }
            });
        });
    }

    // 4. Real-time Automatic Checkout Fee Estimator
    // Designed to instantly calculate expected parking costs in the UI.
    const checkoutSelect = document.getElementById("exit-transaction-select");
    const estimationBox = document.getElementById("fee-estimation-box");
    
    if (checkoutSelect && estimationBox) {
        const estPlate = document.getElementById("est-plate");
        const estSlot = document.getElementById("est-slot");
        const estDuration = document.getElementById("est-duration");
        const estRate = document.getElementById("est-rate");
        const estFee = document.getElementById("est-fee");
        
        const updateFeeEstimation = () => {
            const selectedOption = checkoutSelect.options[checkoutSelect.selectedIndex];
            
            if (!selectedOption || !selectedOption.value) {
                estimationBox.style.display = "none";
                return;
            }
            
            const licensePlate = selectedOption.getAttribute("data-plate");
            const slotNumber = selectedOption.getAttribute("data-slot");
            const vehicleType = selectedOption.getAttribute("data-type");
            const entryTimeStr = selectedOption.getAttribute("data-entry-time"); // Standard ISO/MySQL string
            
            if (!entryTimeStr) {
                estimationBox.style.display = "none";
                return;
            }
            
            // Calculate elapsed time
            const entryTime = new Date(entryTimeStr);
            const now = new Date();
            
            // Difference in seconds
            const diffSeconds = Math.max(0, Math.floor((now - entryTime) / 1000));
            
            // Convert to hours and round up (minimum charge of 1 hour)
            const diffHours = Math.ceil(diffSeconds / 3600);
            const displayHours = diffHours < 1 ? 1 : diffHours;
            
            // Tiers pricing mapping
            let hourlyRate = 5.00;
            if (vehicleType === "Bike") {
                hourlyRate = 2.00;
            } else if (vehicleType === "Car") {
                hourlyRate = 5.00;
            } else if (vehicleType === "Truck") {
                hourlyRate = 10.00;
            }
            
            const totalEstimatedFee = displayHours * hourlyRate;
            
            // Display duration string nicely
            let durationString = "";
            if (diffSeconds < 60) {
                durationString = `${diffSeconds} seconds (1 hr minimum charge)`;
            } else if (diffSeconds < 3600) {
                const mins = Math.floor(diffSeconds / 60);
                durationString = `${mins} min(s) (1 hr minimum charge)`;
            } else {
                const hrs = Math.floor(diffSeconds / 3600);
                const mins = Math.floor((diffSeconds % 3600) / 60);
                durationString = `${hrs} hr(s) ${mins} min(s)`;
            }
            
            // Populate fields
            estPlate.textContent = licensePlate;
            estSlot.textContent = slotNumber;
            estDuration.textContent = durationString;
            estRate.textContent = `$${hourlyRate.toFixed(2)}/hr (${vehicleType})`;
            estFee.textContent = `$${totalEstimatedFee.toFixed(2)}`;
            
            // Fade in box smoothly
            estimationBox.style.display = "block";
            estimationBox.style.animation = "fadeInUp 0.4s ease";
        };
        
        checkoutSelect.addEventListener("change", updateFeeEstimation);
        
        // Run once on load just in case
        updateFeeEstimation();
        
        // Setup an interval to update the countdown/fee every 30 seconds
        setInterval(() => {
            if (checkoutSelect.selectedIndex > 0) {
                updateFeeEstimation();
            }
        }, 30000);
    }
});
