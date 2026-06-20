/* global Vue, axios */

Vue.createApp({
    data() {
        const today = new Date().toISOString().split('T')[0];
        return {
            logsCode: [],
            id_code: '',
            nom_code: '',
            valeur: '',
            description: '',
            date_debut: '',
            date_fin: '',

            selectedCode: {
                id_code: '',
                nom_code: '',
                valeur: '',
                description: '',
                date_debut: '',
                date_fin: ''
            },

            connectedTravailleur: {
                id_travailleur: '',
                nom: '',
                email: '',
                privileges: ''
            },

            afficherFormulaireDelete: false,
            afficherFormulaireUpdate: false,
            afficherFormulaireReactiver: false,
            reactiverDateDebut: today,
        }
    },

    computed: {
        isAdmin() { return this.connectedTravailleur.privileges === 'admin' },

        // Date minimale pour la réactivation
        reactiverDateMin() {
            if (!this.selectedCode.date_fin) return '';
            const d = new Date(this.selectedCode.date_fin);
            d.setDate(d.getDate() + 1);
            return d.toISOString().split('T')[0];
        },
    },

    mounted() {
        const params = new URLSearchParams(window.location.search);
        const user = localStorage.getItem('connectedTravailleur');

        // if connected user exists
        if (user) {
            this.connectedTravailleur = JSON.parse(user);
        }

        this.selectedCode.id_code = params.get('id_code') ?? params.get('id') ?? '';
        this.getCode();
    },
    methods: {
        getCode: function (){
            axios.get('../../api/codes/get_all_logs_code_by_id.php',
                {
                    params: {
                        id_code: this.selectedCode.id_code
                    },
                    headers: {
                        'Content-Type': 'application/json',
                    }
                }
            )
                .then(response => {
                    const rows = Array.isArray(response.data) ? response.data : [];
                    this.logsCode = rows;
                    if (rows.length > 0) {
                        // Ligne courante = date_debut la plus récente
                        this.selectedCode = rows.reduce((latest, row) =>
                            row.date_debut > latest.date_debut ? row : latest
                        );
                    }
                })
                .catch(error => {
                    console.error(error);
                });
        },

        goBack()
        {
            window.location.href = `./codes.html`;
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

        openReactiverForm() {
            if (this.selectedCode.date_fin) {
                const d = new Date(this.selectedCode.date_fin);
                d.setDate(d.getDate() + 1);
                this.reactiverDateDebut = d.toISOString().split('T')[0];
            } else {
                this.reactiverDateDebut = new Date().toISOString().split('T')[0];
            }
            this.afficherFormulaireReactiver = true;
            this.contextMenuVisible = false;
        },

        //Update code
        modCode: function () {
            var contact = {};
            contact['id_code'] = this.selectedCode.id_code;
            contact['nom_code'] = this.selectedCode.nom_code;
            contact['valeur'] = this.selectedCode.valeur;
            contact['description'] = this.selectedCode.description;
            contact['date_debut'] = this.selectedCode.date_debut;
            contact['date_fin'] = this.selectedCode.date_fin ? this.selectedCode.date_fin : null;

            axios.put('../../api/codes/put_code.php', JSON.stringify(contact), {
                headers: {
                    'Content-Type': 'application/json',
                }
            })
                .then(() => {
                    alert('Code Actualisé(e)');
                    this.afficherFormulaireUpdate = false;
                    this.getCode();
                })
                .catch((error) => {
                    alert('Probleme d\'enregistrement');
                    console.log(error);
                });
        },

        // soft-delete
        deleteCode() {
            axios.put('../../api/codes/delete_code.php',
                { id_code: this.selectedCode.id_code },
                { headers: { 'Content-Type': 'application/json' } }
            )
                .then(() => {
                    this.goBack();
                })
                .catch(error => {
                    console.error(error);
                });
        },

        reactiverCode() {
            const contact = {
                id_code: this.selectedCode.id_code,
                date_debut: this.reactiverDateDebut,
            };

            axios.post('../../api/codes/post_reactivate_code.php', JSON.stringify(contact), {
                headers: { 'Content-Type': 'application/json' }
            })
                .then(() => {
                    alert('Code réactivé avec succès');
                    this.afficherFormulaireReactiver = false;
                    this.getCode();
                })
                .catch(error => {
                    alert('Erreur lors de la réactivation');
                    console.error(error);
                });
        },

    },
})
    .component('app-menu', AppMenu)
    .mount('#app');