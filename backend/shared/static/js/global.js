// Scripts globaux - Coucou Beaute

// Configuration globale
window.CoucouBeaute = {
    version: '1.0.0',
    environment: 'development',
    apiBaseUrl: '/api/',

    // Utilitaires
    utils: {
        // Formatage des dates
        formatDate: function (date) {
            return new Intl.DateTimeFormat('fr-FR', {
                year: 'numeric',
                month: 'long',
                day: 'numeric'
            }).format(new Date(date));
        },

        // Formatage des prix
        formatPrice: function (price) {
            return new Intl.NumberFormat('fr-FR', {
                style: 'currency',
                currency: 'EUR'
            }).format(price);
        },

        // Validation des emails
        isValidEmail: function (email) {
            const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
            return emailRegex.test(email);
        }
    },

    // Gestion des notifications
    notifications: {
        show: function (message, type = 'info') {
            // Implementation des notifications
            console.log(`[${type.toUpperCase()}] ${message}`);
        },

        success: function (message) {
            this.show(message, 'success');
        },

        error: function (message) {
            this.show(message, 'error');
        },

        warning: function (message) {
            this.show(message, 'warning');
        }
    }
};

// Initialisation au chargement de la page
document.addEventListener('DOMContentLoaded', function () {
    console.log('Coucou Beaute - Application initialisee');

    // Initialiser les composants globaux
    initializeGlobalComponents();
});

function initializeGlobalComponents() {
    // Initialisation des composants partages
    // Navigation, footer, etc.
}
