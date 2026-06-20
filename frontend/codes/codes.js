/* global Vue, axios */

Vue.createApp({
    data() {
        const today = new Date().toISOString().split('T')[0];
        return {
            id: '',

            codes: [],
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

            afficherFormulaireAjout: false,
            afficherFormulaireUpdate: false,
            afficherFormulaireDelete: false,
            afficherFormulaireReactiver: false,
            reactiverDateDebut: today,

            contextMenuVisible: false,
            contextMenuX: 0,
            contextMenuY: 0,
        }
    },

    computed: {
        isAdmin()   { return this.connectedTravailleur.privileges === 'admin' },
        isManager() { return ['admin', 'contremaitre/manager'].includes(this.connectedTravailleur.privileges) },
        isChef()    { return ['admin', 'contremaitre/manager', 'chef_equipe'].includes(this.connectedTravailleur.privileges) },

        // Date minimale pour la réactivation
        reactiverDateMin() {
            if (!this.selectedCode.date_fin) return '';
            const d = new Date(this.selectedCode.date_fin);
            d.setDate(d.getDate() + 1);
            return d.toISOString().split('T')[0];
        },

        // get code avec date_fin max
        codesFiltered() {
            const map = new Map();
            for (const code of this.codes) {
                const existing = map.get(code.nom_code);
                if (!existing) {
                    map.set(code.nom_code, code);
                } else {
                    // null date_fin = currently active → always wins
                    const existingFin = existing.date_fin  ? new Date(existing.date_fin)  : Infinity;
                    const currentFin  = code.date_fin      ? new Date(code.date_fin)      : Infinity;
                    if (currentFin > existingFin) {
                        map.set(code.nom_code, code);
                    }
                }
            }
            return Array.from(map.values());
        },
    },
    mounted() {
        // load connected user
        const user = localStorage.getItem('connectedTravailleur');
        if (user) {
            this.connectedTravailleur = JSON.parse(user);
        }
        this.getCodes();

        window.addEventListener('click', () => {
            this.contextMenuVisible = false;
        });

        // const params = new URLSearchParams(window.location.search);
    },
    methods: {
        formatDate(dateStr) {
            if (!dateStr) return '';
            const [y, m, d] = dateStr.split('-');
            return `${d}-${m}-${y}`;
        },

        openContextMenu(event, code) {
            this.selectedCode = { ...code };
            this.contextMenuX = event.clientX;
            this.contextMenuY = event.clientY;
            this.contextMenuVisible = true;
        },

        isRowSelected(code) {
            return (this.contextMenuVisible || this.afficherFormulaireUpdate || this.afficherFormulaireDelete)
                && this.selectedCode.id_code === code.id_code;
        },

        //reset form
        resetForm: function () {
            this.nom_code = '';
            this.valeur = '';
            this.description = '';
            this.date_debut = '';
            this.date_fin = '';
        },

        // get codes
        getCodes: function () {
            axios.get('../../api/codes/get_all_codes.php')
                .then(response => { this.codes = response.data })
                .catch(console.error);
        },

        //create code
        createCode: function () {
            const contact = {
                nom_code: this.nom_code,
                description: this.description,
                valeur: this.valeur,
                date_debut: this.date_debut,
                date_fin: this.date_fin ? this.date_fin : null
            };

            axios.post('../../api/codes/post_code.php', JSON.stringify(contact), {
                headers: { 'Content-Type': 'application/json' }
            })
                .then((response) => {
                    const data = response.data;
                    if (data && data.message && !data.message.includes('succès')) {
                        alert(data.message);
                        return;
                    }

                    alert('Code Enregistré(e)');
                    this.afficherFormulaireAjout = false;
                    this.getCodes();
                })
                .catch(error => {
                    alert('Problème d\'enregistrement');
                    console.error(error);
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
                .then((response) => {
                    const data = response.data;
                    if (data && data.message && !data.message.includes('succès')) {
                        alert(data.message);
                        return;
                    }

                    alert('Code Actualisé(e)');
                    this.afficherFormulaireUpdate = false;
                    this.getCodes();
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
                    this.getCodes();
                    this.afficherFormulaireDelete = false;
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
                .then((response) => {
                    const data = response.data;
                    if (data && data.message && !data.message.includes('succès')) {
                        alert(data.message);
                        return;
                    }

                    alert('Code réactivé avec succès');
                    this.afficherFormulaireReactiver = false;
                    this.getCodes();
                })
                .catch(error => {
                    alert('Erreur lors de la réactivation');
                    console.error(error);
                });
        },

        goToPageCode(id) {
            window.location.href = `./page_code.html?id=${id}`;
        },
    }
})
    .component('app-menu', AppMenu)
    .mount('#app');