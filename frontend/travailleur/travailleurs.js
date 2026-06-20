/* global Vue, axios */

Vue.createApp({
    data() {
        return {
            day: '',
            month: '',
            year: '',
            id: '',

            type_contrat: [],
            contrat: {
                id_travailleur: '',
                type_contrat: '',
                heures_journee_travail: 0,
                date_debut: '',
                date_fin: '',
            },

            travailleurs: [],
            id_travailleur: '',
            nom: '',
            no_registre_national: '',
            email: '',
            password: '',

            selectedTravailleur: {
                id_travailleur: '',
                nom: '',
                no_registre_national: '',
                email: '',
                password: ''
            },
            connectedTravailleur: {
                id_travailleur: '',
                nom: '',
                email: '',
                privileges: ''
            },

            afficherFormulaireAjout: false,
            afficherFormulaireUpdate: false,
            afficherFormulaireDelete: false,
            afficherFormulaireContrat: false,

            contextMenuVisible: false,
            contextMenuX: 0,
            contextMenuY: 0,
        }
    },

    computed: {
        isAdmin()   { return this.connectedTravailleur.privileges === 'admin' },
        isManager() { return ['admin', 'contremaitre/manager'].includes(this.connectedTravailleur.privileges) },
        isChef()    { return ['admin', 'contremaitre/manager', 'chef_equipe'].includes(this.connectedTravailleur.privileges) },
    },

    mounted() {
        // load connected user
        const user = localStorage.getItem('connectedTravailleur');
        if (user) {
            this.connectedTravailleur = JSON.parse(user);
        }
        this.getTravailleurs();

        window.addEventListener('click', () => {
            this.contextMenuVisible = false;
        });

        const params = new URLSearchParams(window.location.search);
        this.day = params.get('day');
        this.month = params.get('month');
        this.year = params.get('year');

        axios.get('../../api/get_all_type_contrat.php')
            .then(response => {
                this.type_contrat = response.data.type_contrat;
            })
            .catch(console.error);
    },
    methods: {
        openContextMenu(event, travailleur) {
            this.selectedTravailleur = { ...travailleur };
            this.contextMenuX = event.clientX;
            this.contextMenuY = event.clientY;
            this.contextMenuVisible = true;
        },

        isRowSelected(travailleur) {
            return this.selectedTravailleur.id_travailleur !== '' &&
                String(travailleur.id_travailleur) === String(this.selectedTravailleur.id_travailleur);
        },

        goToProfil(id) {
            window.location.href = `../profil/profil.html?id=${id}`;
        },

        //reset form
        resetForm() {
            this.nom = '';
            this.no_registre_national = '';
            this.email = '';
            this.password = '';
        },

        getTravailleurs() {
            const url = this.isManager
                ? '../../api/travailleur/get_all_travailleur.php'
                : '../../api/travailleur/chef_equipe/get_all_travailleur_by_chef_equipe.php';

            const params =  {
                id_travailleur: this.connectedTravailleur.id_travailleur,
                jour: new Date().getDate(),
                mois: new Date().getMonth() + 1,
                annee: new Date().getFullYear()
            };

            axios.get(url, { params })
                .then(response => {
                    const data = Array.isArray(response.data) ? response.data : [];
                    this.travailleurs = data.filter(t =>
                        String(t.id_travailleur) !== String(this.connectedTravailleur.id_travailleur)
                    );
                })
                .catch(console.error);
        },

        //create travailleur
        createTravailleur() {
            const contact = {
                nom: this.nom,
                privileges: 'travailleur',
                no_registre_national: this.no_registre_national,
                email: this.email,
                password: this.password,
            };

            axios.post('../../api/travailleur/post_travailleur.php', JSON.stringify(contact), {
                    headers: {
                        'Content-Type': 'application/json',
                    },
                })
                .then(response => {
                    const data = response.data;
                    if (data && data.message && !data.message.includes('succès')) {
                        alert(data.message);
                        return;
                    }

                    alert('Travailleur Enregistré(e)');

                    this.selectedTravailleur.id_travailleur = response.data.id_travailleur;
                    this.afficherFormulaireAjout = false;
                    this.resetForm();
                    return axios.get('../../api/travailleur/get_all_travailleur.php');
                })
                .then(response => {
                    const data = Array.isArray(response.data) ? response.data : [];
                    this.travailleurs = data;

                    if (!data.length) {
                        alert('Travailleur créé, creation de contrat impossible pour l\'instant.');
                        return;
                    }

                    const created = data.reduce((a, b) =>
                        Number(a.id_travailleur) > Number(b.id_travailleur) ? a : b
                    );

                    this.selectedTravailleur = { ...this.selectedTravailleur, ...created };
                    this.afficherFormulaireContrat = true;
                })
                .catch(error => {
                    alert('Probleme denregistrement');
                    console.log(error)
                });

        },

        openUpdateForm() {
            this.afficherFormulaireUpdate = true;
            this.contextMenuVisible = false;
        },

        openDeleteForm() {
            this.afficherFormulaireDelete = true;
            this.contextMenuVisible = false;
        },

        openContratForm(){
            this.afficherFormulaireContrat = true;
            this.contextMenuVisible = false;
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
                    this.afficherFormulaireUpdate = false;
                    this.getTravailleurs();
                })
                .catch(error => {
                    alert('Problème d\'enregistrement');
                    console.error(error);
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
                .then((response) => {
                    const data = response.data;
                    if (data && data.message && !data.message.includes('succès')) {
                        alert(data.message);
                        return;
                    }

                    this.getTravailleurs();
                    this.afficherFormulaireDelete = false;
                })
                .catch(console.error);

        },

        formatNrn() {
            let value = this.no_registre_national.replace(/\D/g, '').substring(0, 11);
            if (value.length > 2)  value = value.slice(0, 2)  + '.' + value.slice(2);
            if (value.length > 5)  value = value.slice(0, 5)  + '.' + value.slice(5);
            if (value.length > 8)  value = value.slice(0, 8)  + '-' + value.slice(8);
            if (value.length > 12) value = value.slice(0, 12) + '.' + value.slice(12);
            this.no_registre_national = value;
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
                    this.getTravailleurs();
                })
                .catch(error => {
                    alert('Probleme denregistrement');
                    console.log(error)
                });
        },
    }
})
.component('app-menu', AppMenu)
.mount('#app');