/**
 * Professional Booking System
 * A maintainable, scalable booking system for professional appointments
 */
class BookingSystem {
    constructor() {
        this.data = this.getBookingData();
        this.selectedService = null;
        this.chosenSlot = { start: null, end: null, btn: null };
        this.init();
    }

    getBookingData() {
        const dataEl = document.getElementById('booking-data');
        if (!dataEl) {
            console.error('Booking data element not found');
            return null;
        }
        return {
            proId: dataEl.dataset.proId,
            csrfToken: dataEl.dataset.csrfToken,
            slotsUrl: dataEl.dataset.slotsUrl,
            bookUrl: dataEl.dataset.bookUrl
        };
    }

    init() {
        if (!this.data) return;
        this.bindEvents();
        this.handleUrlParams();
    }

    bindEvents() {
        // Booking buttons
        document.addEventListener('click', (e) => {
            if (e.target.closest('.booking-btn')) {
                const btn = e.target.closest('.booking-btn');
                this.openBooking({
                    name: btn.dataset.serviceName,
                    duration: parseInt(btn.dataset.serviceDuration) || 60,
                    price: parseFloat(btn.dataset.servicePrice) || 0
                });
            }
        });

        // Modal close
        document.addEventListener('click', (e) => {
            if (e.target.id === 'bookingModal' || e.target.closest('.close-booking')) {
                this.closeBooking();
            }
        });

        // Date change
        const dateInput = document.getElementById('bookingDate');
        if (dateInput) {
            dateInput.addEventListener('change', () => this.loadSlots());
        }

        // Service change
        const serviceSelect = document.getElementById('bookingServiceSelect');
        if (serviceSelect) {
            serviceSelect.addEventListener('change', (e) => this.onServiceChange(e.target));
        }

        // Submit booking
        const submitBtn = document.querySelector('.submit-booking');
        if (submitBtn) {
            submitBtn.addEventListener('click', () => this.submitBooking());
        }
    }

    handleUrlParams() {
        const params = new URLSearchParams(window.location.search);
        if (params.get('book') === '1') {
            this.openBooking();
        }
    }

    openBooking(service = null) {
        this.selectedService = service;

        // Update UI
        const serviceNameEl = document.getElementById('bookingServiceName');
        const servicePriceEl = document.getElementById('bookingServicePrice');
        const modal = document.getElementById('bookingModal');
        const dateInput = document.getElementById('bookingDate');

        if (serviceNameEl) serviceNameEl.textContent = service?.name || 'Service';
        if (servicePriceEl) servicePriceEl.textContent = (service?.price || 0) + ' DT';
        if (modal) modal.classList.remove('hidden');
        if (dateInput) {
            const today = new Date().toISOString().slice(0, 10);
            dateInput.value = today;
        }

        // Sync service dropdown
        this.syncServiceDropdown(service?.name);

        // Load slots
        this.loadSlots();
    }

    syncServiceDropdown(serviceName) {
        const select = document.getElementById('bookingServiceSelect');
        if (!select) return;

        if (serviceName) {
            for (let i = 0; i < select.options.length; i++) {
                if (select.options[i].value === serviceName) {
                    select.selectedIndex = i;
                    this.onServiceChange(select);
                    return;
                }
            }
        }

        if (select.options.length > 0) {
            select.selectedIndex = 0;
            this.onServiceChange(select);
        }
    }

    closeBooking() {
        const modal = document.getElementById('bookingModal');
        if (modal) modal.classList.add('hidden');
        this.resetSelection();
    }

    resetSelection() {
        this.selectedService = null;
        this.chosenSlot = { start: null, end: null, btn: null };
    }

    async loadSlots() {
        const date = document.getElementById('bookingDate')?.value;
        const slotsWrap = document.getElementById('slotsWrap');

        if (!date) {
            if (slotsWrap) slotsWrap.innerHTML = '<div class="text-gray-500">Veuillez sélectionner une date.</div>';
            return;
        }

        if (slotsWrap) slotsWrap.innerHTML = '<div class="text-gray-600">Chargement des créneaux...</div>';

        try {
            const url = `${this.data.slotsUrl}?pro_id=${this.data.proId}&date=${date}`;
            const response = await fetch(url, { credentials: 'include' });
            const data = await response.json();
            const slots = data.results || [];

            if (!slots.length) {
                if (slotsWrap) slotsWrap.innerHTML = '<div class="text-gray-500">Aucun créneau disponible pour cette date.</div>';
                return;
            }

            this.renderSlots(slots, slotsWrap);
        } catch (error) {
            console.error('Error loading slots:', error);
            if (slotsWrap) slotsWrap.innerHTML = '<div class="text-red-500">Erreur lors du chargement des créneaux.</div>';
        }
    }

    renderSlots(slots, container) {
        if (!container) return;

        container.innerHTML = '';

        slots.forEach(slot => {
            const disabled = slot.status !== 'available';
            const btn = document.createElement('button');
            btn.className = `px-4 py-2 rounded-xl border text-sm transition-all ${disabled
                    ? 'bg-gray-100 text-gray-400 cursor-not-allowed'
                    : 'bg-white hover:bg-pink-50 border-pink-200 text-gray-700 hover:border-pink-300'
                }`;

            const from = new Date(slot.start);
            const to = new Date(slot.end);
            const label = `${from.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })} - ${to.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })}`;
            btn.textContent = label;

            if (!disabled) {
                btn.addEventListener('click', () => this.selectSlot(slot.start, slot.end, btn));
            }

            container.appendChild(btn);
        });
    }

    selectSlot(start, end, btn) {
        // Remove previous selection
        if (this.chosenSlot.btn) {
            this.chosenSlot.btn.classList.remove('ring-2', 'ring-pink-400', 'bg-pink-50');
        }

        // Set new selection
        this.chosenSlot = { start, end, btn };
        btn.classList.add('ring-2', 'ring-pink-400', 'bg-pink-50');
    }

    onServiceChange(select) {
        if (!select) return;

        const option = select.options[select.selectedIndex];
        if (!option) return;

        this.selectedService = {
            name: option.value || 'Service',
            price: parseFloat(option.dataset.price || '0') || 0,
            duration: parseInt(option.dataset.duration || '60') || 60,
        };

        const serviceNameEl = document.getElementById('bookingServiceName');
        const servicePriceEl = document.getElementById('bookingServicePrice');

        if (serviceNameEl) serviceNameEl.textContent = this.selectedService.name;
        if (servicePriceEl) servicePriceEl.textContent = (this.selectedService.price || 0) + ' DT';
    }

    async submitBooking() {
        if (!this.chosenSlot.start || !this.chosenSlot.end) {
            this.showAlert('Veuillez sélectionner un créneau.', 'warning');
            return;
        }

        const payload = {
            pro_id: parseInt(this.data.proId),
            service_name: this.selectedService?.name || 'Service',
            price: this.selectedService?.price || 0,
            start: this.chosenSlot.start,
            end: this.chosenSlot.end,
        };

        try {
            const response = await fetch(this.data.bookUrl, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                    'X-CSRFToken': this.data.csrfToken
                },
                credentials: 'include',
                body: JSON.stringify(payload)
            });

            if (response.ok) {
                this.showAlert('Votre demande de rendez-vous a été envoyée. Vous recevrez un email après confirmation.', 'success');
                this.closeBooking();
            } else {
                const error = await response.json().catch(() => ({}));
                this.showAlert('Erreur: ' + (error.detail || 'Impossible de réserver'), 'error');
            }
        } catch (error) {
            console.error('Booking error:', error);
            this.showAlert('Erreur: Impossible de réserver', 'error');
        }
    }

    showAlert(message, type = 'info') {
        // Enhanced alert system - can be replaced with a proper notification component
        const alertClass = {
            'success': 'bg-green-100 text-green-800 border-green-200',
            'error': 'bg-red-100 text-red-800 border-red-200',
            'warning': 'bg-yellow-100 text-yellow-800 border-yellow-200',
            'info': 'bg-blue-100 text-blue-800 border-blue-200'
        }[type] || 'bg-blue-100 text-blue-800 border-blue-200';

        // Create a temporary alert element
        const alertEl = document.createElement('div');
        alertEl.className = `fixed top-4 right-4 z-50 px-6 py-3 rounded-lg border ${alertClass} shadow-lg transition-all duration-300`;
        alertEl.textContent = message;

        document.body.appendChild(alertEl);

        // Auto remove after 5 seconds
        setTimeout(() => {
            alertEl.style.opacity = '0';
            alertEl.style.transform = 'translateX(100%)';
            setTimeout(() => {
                if (alertEl.parentNode) {
                    alertEl.parentNode.removeChild(alertEl);
                }
            }, 300);
        }, 5000);
    }
}

// Utility function for copying to clipboard
function copyToClipboard(text) {
    navigator.clipboard.writeText(text).then(function () {
        const button = event.target.closest('button');
        if (!button) return;

        const originalText = button.innerHTML;
        button.innerHTML = '<i data-lucide="check" class="w-4 h-4"></i> Copié!';
        button.classList.add('bg-green-100', 'text-green-700', 'border-green-300');

        setTimeout(() => {
            button.innerHTML = originalText;
            button.classList.remove('bg-green-100', 'text-green-700', 'border-green-300');
            if (window.lucide) window.lucide.createIcons();
        }, 2000);
    }).catch(function (err) {
        console.error('Erreur lors de la copie: ', err);
        alert('Impossible de copier l\'adresse');
    });
}

// Initialize booking system when DOM is ready
document.addEventListener('DOMContentLoaded', () => {
    new BookingSystem();
});

// Export for potential external use
window.BookingSystem = BookingSystem;
