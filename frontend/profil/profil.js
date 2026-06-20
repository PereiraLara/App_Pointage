/* global Vue, axios */

Vue.createApp({
    data() {
        return {
            id_travailleur: '',
            nom: '',
            no_registre_national: '',
            email: '',
            contrats:[],
            type_contrat: [],

            connectedTravailleur: {
                id_travailleur: '',
                nom: '',
                email: '',
                privileges: ''
            },

            selectedTravailleur: {
                id_travailleur: '',
                nom: '',
                no_registre_national: '',
                email: ''
            },

            contrat:{
              type_contrat: '',
              heures_journee_travail:'',
              date_debut: '',
              date_fin: ''
            },

            afficherFormulaireUpdate: false,
            afficherFormulaireContrat: false,
            afficherFormulaireDelete: false,

        }
    },

    computed: {
        isAdmin() { return this.connectedTravailleur.privileges === 'admin' },
        isManager() { return ['admin', 'contremaitre/manager'].includes(this.connectedTravailleur.privileges) },
        isChef() { return ['admin', 'contremaitre/manager', 'chef_equipe'].includes(this.connectedTravailleur.privileges) },
    },

    mounted() {
        const params = new URLSearchParams(window.location.search);
        const user = localStorage.getItem('connectedTravailleur');

        // if connected user exists
        if (user) {
            this.connectedTravailleur = JSON.parse(user);

            // if URL has id use it
            if (params.get('id')) {
                this.id_travailleur = params.get('id');
            } else {
                // otherwise use connected user id
                this.id_travailleur = this.connectedTravailleur.id_travailleur;
            }
        } else {
            // fallback
            this.id_travailleur = params.get('id');
        }

        axios.get('../../api/get_all_type_contrat.php')
            .then(response => {
                this.type_contrat = response.data.type_contrat;
            })
            .catch(console.error);

        this.getTravailleur();


    },
    methods: {
        getTravailleur: function(){
            axios.post('../../api/travailleur/get_one_travailleur.php',
                {
                    id_travailleur: this.id_travailleur
                },
                {
                    headers: {
                        'Content-Type': 'application/json',
                    }
                }
            )
                .then(response => {
                    console.log(response.data);
                    this.selectedTravailleur = response.data;

                    axios.get('../../api/travailleur/contrat/get_all_contrats_by_id_travailleur.php',
                        {
                            params: {
                                id_travailleur: this.selectedTravailleur.id_travailleur
                            },
                            headers: {
                                'Content-Type': 'application/json',
                            }
                        })
                        .then(response => {
                            console.log(response.data);
                            this.contrats = response.data;
                        })
                        .catch(error => {
                            console.error(error);
                        });
                })
                .catch(error => {
                    console.error(error);
                });
        },

        formatDate(dateStr) {
            if (!dateStr) return '';
            const [y, m, d] = dateStr.split('-');
            return `${d}-${m}-${y}`;
        },

        goToHistorique(id)
        {
            window.location.href = `historique.html?id=${id}`;
        },

        deconnect()
        {
            axios.post('../../api/travailleur/logout.php',
                {
                    id_travailleur: this.id_travailleur
                },
                {
                    headers: {
                        'Content-Type': 'application/json',
                    }
                }
            )
                .then(response => {
                    localStorage.clear();
                    console.log(response.data);
                    window.location.href = `../index.html`;
                })
                .catch(error => {
                    console.error(error);
                });
        },

        openUpdateForm() {
            this.afficherFormulaireUpdate = true;
        },

        openContratForm(){
            this.afficherFormulaireContrat = true;
        },

        openDeleteForm() {
            this.afficherFormulaireDelete = true;
        },

        //Update travailleur
        modTravailleur() {
            const contact = {
                id_travailleur: this.selectedTravailleur.id_travailleur,
                nom: this.selectedTravailleur.nom,
                no_registre_national: this.selectedTravailleur.no_registre_national,
                email: this.selectedTravailleur.email,
                password: this.selectedTravailleur.password,
            };

            axios.put('../../api/travailleur/put_travailleur.php', JSON.stringify(contact), {
                headers: {
                    'Content-Type': 'application/json',
                }
            })
                .then((response) => {
                    const data = response.data;
                    if (data && data.message && !data.message.includes('succès')) {
                        alert(data.message);
                        return;
                    }

                    alert('Travailleur Actualisé');
                    this.getTravailleur();
                    this.afficherFormulaireUpdate = false;
                })
                .catch(error => {
                    alert('Problème d\'enregistrement');
                    console.error(error);
                });
        },

        formatNrnUpdate() {
            let value = this.selectedTravailleur.no_registre_national.replace(/\D/g, '').substring(0, 11);
            if (value.length > 2)  value = value.slice(0, 2)  + '.' + value.slice(2);
            if (value.length > 5)  value = value.slice(0, 5)  + '.' + value.slice(5);
            if (value.length > 8)  value = value.slice(0, 8)  + '-' + value.slice(8);
            if (value.length > 12) value = value.slice(0, 12) + '.' + value.slice(12);
            this.selectedTravailleur.no_registre_national = value;
        },

        createContrat(){
            const contact = {
                id_travailleur: this.selectedTravailleur.id_travailleur,
                type_contrat: this.contrat.type_contrat,
                heures_journee_travail: this.contrat.heures_journee_travail,
                date_debut: this.contrat.date_debut,
                date_fin: this.contrat.date_fin ? this.contrat.date_fin : null,
            };


            axios.post('../../api/travailleur/contrat/post_contrat.php', JSON.stringify(contact), {
                headers: {
                    'Content-Type': 'application/json',
                },
            })
                .then((response) => {
                    const data = response.data;
                    if (data && data.message && !data.message.includes('succès')) {
                        alert(data.message);
                        return;
                    }

                    alert('Contrat Enregistre(e)');
                    this.afficherFormulaireContrat = false;
                    this.contrat.id_travailleur = '';
                    this.contrat.type_contrat = '';
                    this.contrat.heures_journee_travail = 0;
                    this.contrat.date_debut = '';
                    this.contrat.date_fin = '';
                    this.getTravailleur();
                })
                .catch(error => {
                    alert('Probleme denregistrement');
                    console.log(error)
                });
        },

        deleteTravailleur() {
            axios.delete('../../api/travailleur/delete_travailleur.php',
                {
                    data: {
                        id_travailleur: this.selectedTravailleur.id_travailleur,
                        date_fin: new Date().toISOString().split('T')[0]
                    },
                    headers: {'Content-Type': 'application/json'}
                }
            )
                .then(() => {
                    window.location.href = `../travailleur/travailleurs.html`;
                })
                .catch(console.error);

        },
    }
})
    .component('app-menu', AppMenu)
    .mount('#app');