/* global Vue, axios */

Vue.createApp({
    data() {
        return {
            id_travailleur: '',

            id_equipe: '',
            nom_equipe: '',
            specialisation: '',
            capacite: '',
            chef_de_equipe: '',
            parent_id: '',
            travailleurs: [],
            allTravailleurs: [],
            equipes: [],

            connectedTravailleur: {
                id_travailleur: '',
                privileges: ''
            },

            selectedEquipe: {
                id_equipe: '',
                nom_equipe: '',
                specialisation: '',
                capacite: '',
                chef_de_equipe: '',
                parent_id: ''
            },

            formulaireAssignerTravailleur : false,
            afficherFormulaireUpdate: false,
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
            this.id_travailleur = this.connectedTravailleur.id_travailleur;

            this.id_equipe = params.get('id');
        }

        this.getEquipe();
        this.getEquipes();
        this.getTravailleurs();
    },
    methods: {
        getEquipe: function(){
            axios.post('../../api/equipe/get_one_equipe.php',
                {
                    id_equipe: this.id_equipe
                },
                {
                    headers: {
                        'Content-Type': 'application/json',
                    }
                }
            )
            .then(response => {
                console.log(response.data);
                this.selectedEquipe = response.data;

                if (this.connectedTravailleur.privileges === 'chef_equipe')
                {
                    if(String(this.selectedEquipe.chef_de_equipe) !== String(this.connectedTravailleur.id_travailleur))
                    {
                        window.location.href = `./equipes.html`;
                    }
                }
            })
            .catch(error => {
                console.error(error);
            });

            axios.get('../../api/equipe/travailleur/get_travailleurs_by_equipe.php',
                {
                    params: { id_equipe: this.id_equipe }
                })
            .then(response => {
                console.log(response.data);
                this.travailleurs = response.data;
            })
            .catch(error => {
                console.error(error);
            });
        },

        getTravailleurs: function (){
            axios.get('../../api/travailleur/get_all_travailleurs_actifs.php')
                .then(response => {
                    this.allTravailleurs = response.data
                });
        },
        getEquipes: function (){
            axios.get('../../api/equipe/get_all_equipe.php')
                .then(response => {
                    this.equipes = response.data
                        .filter(e => e.id_equipe !== this.selectedEquipe.id_equipe
                        && e.parent_id !== this.selectedEquipe.id_equipe)
                });
        },

        goToStats(id)
        {
            window.location.href = `stats/stats_equipe.html?id=${id}`;
        },

        goToProfil(id)
        {
            window.location.href = `../profil/profil.html?id=${id}`;
        },

        openAssignmentForm() {
            this.formulaireAssignerTravailleur = true;

            axios.get('../../api/travailleur/get_all_travailleurs_actifs.php')
                .then(response => {
                    this.travailleurs = response.data
                        .filter(t => t.id_travailleur !== this.selectedEquipe.chef_de_equipe)
                        .map(t => ({
                            ...t,
                            checked: false,
                            wasAssigned: false
                        }));

                    return axios.get('../../api/equipe/travailleur/get_travailleurs_by_equipe.php',
                        {
                            params: { id_equipe: this.selectedEquipe.id_equipe }
                        })
                        .then(r => {
                            const assignedIds = Array.isArray(r.data) ? r.data
                                // .filter(t => t.id_travailleur !== this.selectedEquipe.chef_de_equipe)
                                .map(t => t.id_travailleur) : [];
                            this.travailleurs = this.travailleurs.map(t => ({
                                ...t,
                                checked: assignedIds.includes(t.id_travailleur),
                                wasAssigned: assignedIds.includes(t.id_travailleur)
                            }));
                            this.formulaireAssignerTravailleur = true;
                            this.contextMenuVisible = false;
                        });
                });
        },

        openUpdateForm() {
            this.afficherFormulaireUpdate = true;
        },

        openDeleteForm() {
            this.afficherFormulaireDelete = true;
        },


        //Update equipe
        modEquipe: function () {
            var contact = {};
            contact['id_equipe'] = this.selectedEquipe.id_equipe;
            contact['nom_equipe'] = this.selectedEquipe.nom_equipe;
            contact['specialisation'] = this.selectedEquipe.specialisation;
            contact['capacite'] = this.selectedEquipe.capacite;
            contact['chef_de_equipe'] = this.selectedEquipe.chef_de_equipe;
            contact['parent_id'] = this.selectedEquipe.parent_id ? this.selectedEquipe.parent_id : '';

            axios
                .put('../../api/equipe/put_equipe.php', JSON.stringify(contact), {
                    headers: {
                        'Content-Type': 'application/json',
                    }
                })
                .then(() => {
                    //handle sucess
                    alert('Equipe Actualise(e)');
                    this.getEquipe();
                    this.afficherFormulaireUpdate = false;
                })
                .catch(() => {
                    //handle error
                    alert('Probleme d\'enregistrement');
                    this.getEquipe();
                });
        },

        deleteEquipe() {
            const today = new Date().toISOString().split('T')[0];

            axios.put('../../api/equipe/put_delete_equipe.php',
                { id_equipe: this.selectedEquipe.id_equipe, date_fin: today },
                { headers: { 'Content-Type': 'application/json' } }
            )
                .then(() => {
                    window.location.href = `./equipes.html`;
                })
                .catch(error => {
                    console.error(error);
                });
        },

        assignTravailleur: function() {
            const checked   = this.travailleurs.filter(t => t.checked);
            const unchecked = this.travailleurs.filter(t => !t.checked && t.wasAssigned)

            if (checked.length > this.selectedEquipe.capacite - 1) {
                alert('Maximum travailleurs depasse.');
                return;
            }

            const today = new Date().toISOString().split('T')[0];
            const promises = [];

            checked.filter(t => !t.wasAssigned)
                .forEach(t => {
                    promises.push(
                        axios.post('../../api/equipe/travailleur/post_travailleur_equipe.php', {
                            id_equipe:      this.selectedEquipe.id_equipe,
                            id_travailleur: t.id_travailleur,
                            role:           'employe',
                            date_debut:     today
                        }, { headers: { 'Content-Type': 'application/json' } })
                    );
                });
            unchecked.forEach(t => {
                promises.push(
                    axios.put('../../api/equipe/travailleur/put_travailleur_equipe.php', {
                        id_equipe:      this.selectedEquipe.id_equipe,
                        id_travailleur: t.id_travailleur,
                        date_fin:       today
                    }, { headers: { 'Content-Type': 'application/json' } })
                );
            });

            Promise.all(promises)
                .then(() => {
                    alert('Assignations mises à jour.');
                    this.formulaireAssignerTravailleur = false;
                    this.getEquipe();
                })
                .catch(err => {
                    alert('Erreur lors de l\'assignation.');
                    console.error(err);
                });
        },

    }
})
    .component('app-menu', AppMenu)
    .mount('#app');