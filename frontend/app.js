/* global Vue, axios */

Vue.createApp({
    data() {
        return {
            id_travailleur: '',
            nom: '',
            no_registre_national: '',
            email: '',
            password: '',

            connectedTravailleur: {
                id_travailleur: '',
                nom: '',
                email: '',
                privileges: ''
            },
        }
    },
    mounted() {

    },
    methods: {
        //connexion check si email et password sont corrects
        connectUser: function () {
            var contact = {};
            contact['email'] = this.email;
            contact['password'] = this.password;

            axios.post('../api/travailleur/get_travailleur_by_email.php',
                contact,
                {
                    headers: {
                        'Content-Type': 'application/json',
                    },
                })
                .then((response) => {
                    console.log(response.data);
                    // if email correct
                    if (!response.data.message) {
                        alert('Connexion réussie');
                        // ou sessions php
                        localStorage.setItem('connectedTravailleur', JSON.stringify(response.data));

                        if (response.data.privileges === 'travailleur') window.location.href = "profil/profil.html";
                        // redirect to index page
                        else window.location.href = "travailleur/travailleurs.html";
                    } else {
                        alert(response.data.message);
                    }
                })
                .catch((error) => {
                    console.error(error);
                });
        },


    }
})
.component('app-menu', AppMenu)
.mount('#app');