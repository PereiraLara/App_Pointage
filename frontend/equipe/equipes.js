/* global Vue, axios */

Vue.createApp({
    data() {
        return {
            id: '',

            equipes: [],
            travailleurs: [],
            selectedTravailleur: [],
            id_equipe: '',
            nom_equipe: '',
            specialisation: '',
            capacite: '',
            chef_de_equipe: '',
            parent_id: '',

            selectedEquipe: {
                id_equipe: '',
                nom_equipe: '',
                specialisation: '',
                capacite: '',
                parent_id: ''
            },
            connectedTravailleur: {
                id_travailleur: '',
                nom: '',
                email: '',
                privileges: ''
            },

            afficherFormulaireAjout: false,
            formulaireAssignerTravailleur : false,
            afficherFormulaireUpdate: false,
            afficherFormulaireDelete: false,

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
        this.getEquipes();
        this.getTravailleurs();

        window.addEventListener('click', () => {
            this.contextMenuVisible = false;
        });

        const params = new URLSearchParams(window.location.search);

    },
    methods: {

        openContextMenu(event, equipe) {
            this.selectedEquipe = { ...equipe };
            this.contextMenuX = event.clientX;
            this.contextMenuY = event.clientY;
            this.contextMenuVisible = true;
        },

        isRowSelected(equipe) {
            return this.selectedEquipe.id_equipe !== '' &&
                String(equipe.id_equipe) === String(this.selectedEquipe.id_equipe);
        },

        goToPageEquipe(id) {
            window.location.href = `page_equipe.html?id=${id}`;
        },

        //reset form
        resetForm: function () {
            this.nom_equipe = '';
            this.specialisation = '';
            this.capacite = '';
            this.chef_de_equipe = '';
            this.parent_id = '';
        },

        // get equipe
        getEquipes: function () {
            if (this.connectedTravailleur.privileges === 'chef_equipe') {
                axios.get('../../api/equipe/get_all_equipe_by_chef_equipe.php', {
                    params: { id_travailleur: this.connectedTravailleur.id_travailleur }
                }).then(response => (this.equipes = Array.isArray(response.data) ? response.data : []))
            }
            else {
                axios.get('../../api/equipe/get_all_equipe.php')
                    .then(response => (this.equipes = Array.isArray(response.data) ? response.data : []))
            }
        },

        getTravailleurs: function (){
            axios.get('../../api/travailleur/get_all_travailleurs_actifs.php')
                .then(response => {
                    this.travailleurs = response.data
                });
        },

        //create equipe
        createEquipe: function () {
            const today = new Date().toISOString().split('T')[0];

            const contact = {
                nom_equipe:    this.nom_equipe,
                specialisation: this.specialisation,
                capacite:      this.capacite,
                chef_de_equipe: this.chef_de_equipe,
                parent_id:     this.parent_id
            };

            axios.post('../../api/equipe/post_equipe.php', JSON.stringify(contact), {
                headers: { 'Content-Type': 'application/json' }
            })
                .then(response => {
                    alert('Equipe Enregistré(e)');
                    this.afficherFormulaireAjout = false;

                    return axios.post('../../api/equipe/travailleur/post_travailleur_equipe.php', {
                        id_equipe: response.data.id_equipe,
                        id_travailleur: this.chef_de_equipe,
                        role: 'chef',
                        date_debut: today
                    }, { headers: { 'Content-Type': 'application/json' } });
                })
                .then(() => {
                    return axios.get('../../api/equipe/get_all_equipe.php');
                })
                .then(r => {
                    this.equipes = r.data;
                    this.selectedEquipe = r.data.reduce((a, b) =>
                        Number(a.id_equipe) > Number(b.id_equipe) ? a : b
                    );
                    this.openAssignmentForm();
                })
                .catch(response => {
                    alert('Problème d\'enregistrement');
                    console.log(response);
                });
        },

        openAssignmentForm() {
            this.formulaireAssignerTravailleur = true;
            this.contextMenuVisible = false;

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
            this.contextMenuVisible = false;
        },

        openDeleteForm() {
            this.afficherFormulaireDelete = true;
            this.contextMenuVisible = false;
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

            axios.put('../../api/equipe/put_equipe.php', JSON.stringify(contact), {
                    headers: {
                        'Content-Type': 'application/json',
                    }
                })
                .then(() => {
                    //handle sucess
                    alert('Equipe Actualise(e)');
                    this.afficherFormulaireUpdate = false;
                    this.getEquipes();
                })
                .catch(error => {
                    console.error(error);
                });
        },

        deleteEquipe() {
            const today = new Date().toISOString().split('T')[0];

            axios.put('../../api/equipe/put_delete_equipe.php',
                { id_equipe: this.selectedEquipe.id_equipe, date_fin: today },
                { headers: { 'Content-Type': 'application/json' } }
            )
                .then(() => {
                    this.getEquipes();
                    this.afficherFormulaireDelete = false;
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
                })
                .catch(err => {
                    alert('Erreur lors de l\'assignation.');
                    console.error(err);
                });
        }

    }
})
.component('app-menu', AppMenu)
.mount('#app');