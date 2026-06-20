/* global Vue, axios */

Vue.createApp({
    data() {
        return {
            joursFeries: [],
            nom_ferie: '',
            decalage_jours: '',
            date_debut: '',
            date_fin: '',
            legal: 1,

            selectedFerie: {
                id_ferie: '',
                nom_ferie: '',
                decalage_jours:'',
                date_debut: '',
                date_fin: '',
                legal: 1
            },

            afficherFormulaireAjout:  false,
            afficherFormulaireUpdate: false,


            connectedTravailleur: {
                id_travailleur: '',
                nom: '',
                email: '',
                privileges: ''
            },

            mois: [
                { value: '01', label: 'Janvier' },
                { value: '02', label: 'Février' },
                { value: '03', label: 'Mars' },
                { value: '04', label: 'Avril' },
                { value: '05', label: 'Mai' },
                { value: '06', label: 'Juin' },
                { value: '07', label: 'Juillet' },
                { value: '08', label: 'Août' },
                { value: '09', label: 'Septembre' },
                { value: '10', label: 'Octobre' },
                { value: '11', label: 'Novembre' },
                { value: '12', label: 'Décembre' },
            ],

            afficherFormulaireDelete: false,
        }
    },

    computed: {
        isAdmin() { return this.connectedTravailleur.privileges === 'admin' },
    },

    mounted() {
        const params = new URLSearchParams(window.location.search);
        const user = localStorage.getItem('connectedTravailleur');

        // if connected user exists
        if (user) {
            this.connectedTravailleur = JSON.parse(user);
        }

        this.selectedFerie.id_ferie = params.get('id_ferie') ?? params.get('id') ?? '';
        this.getFerie();
    },
    methods: {
        getFerie: function (){
            axios.get('../../api/feries/mobiles/get_ferie_mobile_by_id.php',
                {
                    params: {
                        id_ferie: this.selectedFerie.id_ferie
                    },
                    headers: {
                        'Content-Type': 'application/json',
                    }
                }
            )
                .then(response => {
                    this.selectedFerie = response.data;

                    axios.get('../../api/feries/mobiles/get_all_jours_ferie_mobile.php',
                        {
                            params: {
                                id_ferie: this.selectedFerie.id_ferie
                            },
                            headers: {
                                'Content-Type': 'application/json',
                            }
                        })
                        .then(response => {
                            this.joursFeries = response.data;
                        })
                        .catch(error => {
                            console.error(error);
                        });
                })
                .catch(error => {
                    console.error(error);
                });
        },

        goBack()
        {
            window.location.href = `./feries.html`;
        },

        formatDate(dateStr) {
            if (!dateStr) return '';
            const [y, m, d] = dateStr.split('-');
            return `${d}-${m}-${y}`;
        },

        openUpdateForm() {
            this.afficherFormulaireUpdate = true;
        },

        openDeleteForm() {
            this.afficherFormulaireDelete = true;
        },

        modFerie() {
            const payload = {
                id_ferie: this.selectedFerie.id_ferie,
                nom_ferie: this.selectedFerie.nom_ferie,
                decalage_jours: parseInt(this.selectedFerie.decalage_jours, 10),
                date_debut: this.selectedFerie.date_debut,
                date_fin: this.selectedFerie.date_fin || null,
                legal: this.selectedFerie.legal ? 1 : 0
            };
            axios.put('../../api/feries/mobiles/put_ferie_mobile.php', JSON.stringify(payload), {
                headers: { 'Content-Type': 'application/json' }
            })
                .then(() => {
                    alert('Férié mobile modifié.');
                    this.afficherFormulaireUpdate = false;
                    this.getFerie();
                })
                .catch(err => {
                    alert('Erreur de modification.');
                    console.error(err);
                });
        },

        deleteFerie() {
            axios.put('../../api/feries/mobiles/delete_ferie_mobile.php',
                { id_ferie: this.selectedFerie.id_ferie },
                { headers: { 'Content-Type': 'application/json' } }
            )
                .then(() => {
                    this.goBack();
                })
                .catch(err => console.error(err));
        },

    },
})
    .component('app-menu', AppMenu)
    .mount('#app');