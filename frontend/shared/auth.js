/* global Vue, axios */
axios.interceptors.response.use(
    response => response,
    error => {
        if (error.response?.status === 401) {
            localStorage.removeItem('connectedTravailleur');
            window.location.href = '../index.html';
        }
        if (error.response?.status === 403) {
            alert('Accès refusé');
        }
        return Promise.reject(error);
    }
);