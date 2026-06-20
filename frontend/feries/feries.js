/* global Vue, axios */

Vue.createApp({
    data() {
        return {
            // tab
            activeTab: 'fixes',   // 'fixes' || 'mobiles'
            currentYear: new Date().getFullYear(),
            current_day: new Date().toISOString().split('T')[0],

            // feries fixes
            feries: [],
            nom_ferie: '',
            event_month: '',
            event_day: '',
            // legal: '',
            event_date: '',
            date_debut: '',
            date_fin: '',

            selectedFerie: {
                id_ferie: '',
                nom_ferie: '',
                legal: '',
                event_date: '',
                event_month: '',
                event_day: '',
                date_debut: '',
                date_fin: ''
            },

            afficherFormulaireAjout: false,
            afficherFormulaireUpdate: false,

            // feries mobiles
            feriesMobiles: [],
            nom_ferie_mobile: '',
            decalage_jours: '',
            date_debut_mobile: '',
            date_fin_mobile: '',
            legal: 1,

            selectedFerieMobile: {
                id_ferie: '',
                nom_ferie: '',
                decalage_jours:'',
                date_debut: '',
                date_fin: '',
                legal: 1
            },

            afficherFormulaireAjoutMobile:  false,
            afficherFormulaireUpdateMobile: false,

            // shared
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

            contextMenuVisible: false,
            contextMenuX: 0,
            contextMenuY: 0,
            contextMenuType: 'fixes',   // 'fixes' || 'mobiles'
        }
    },

    computed: {
        isAdmin()   { return this.connectedTravailleur.privileges === 'admin' },
    },
    mounted() {
        // load connected user
        const user = localStorage.getItem('connectedTravailleur');

        if (user) {
            this.connectedTravailleur = JSON.parse(user);
        }
        this.getFeries();
        this.getFeriesMobiles();

        window.addEventListener('click', () => {
            this.contextMenuVisible = false;
        });
    },
    methods: {
        goToPageFerie(id) {
            window.location.href = `./page_ferie.html?id=${id}`;
        },

        isRowSelected(ferie) {
            return this.selectedFerie.id_ferie !== '' &&
                String(ferie.id_ferie) === String(this.selectedFerie.id_ferie);
        },

        // Affichage convivial "jour mois" dans le tableau
        formatEventDate(eventDate) {
            if (!eventDate) return '';
            const [month, day] = eventDate.split('-');
            const moisTrouve = this.mois.find(m => m.value === month);
            return moisTrouve ? `${day} ${moisTrouve.label}` : eventDate;

            // if (!eventDate) return '';
            // const parts = eventDate.split('-');
            // const month = parts[1], day = parts[2];
            // const moisTrouve = this.mois.find(m => m.value === month);
            // return moisTrouve ? `${day} ${moisTrouve.label}` : eventDate;
        },

        formatDate(dateStr) {
            if (!dateStr) return '';
            const [y, m, d] = dateStr.split('-');
            return `${d}-${m}-${y}`;
        },

        formatDateMonth(dateStr) {
            if (!dateStr) return '';
            const [m, d] = dateStr.split('-');
            return `${d}-${m}`;
        },

        maxDayForMonth(month) {
            if (!month) return 31;
            const joursParMois = {
                '01': 31, '02': 29, '03': 31, '04': 30,
                '05': 31, '06': 30, '07': 31, '08': 31,
                '09': 30, '10': 31, '11': 30, '12': 31
            };
            return joursParMois[month] || 31;
        },

        openContextMenu(event, item, type) {
            event.stopPropagation();
            this.contextMenuType = type;
            if (type === 'fixes') {
                this.selectedFerie = { ...item };
                if (item.event_date) {
                    const [month, day] = item.event_date.split('-');
                    this.selectedFerie.event_month = month || '';
                    this.selectedFerie.event_day   = day   || '';
                }
            } else {
                this.selectedFerieMobile = { ...item };
            }
            this.contextMenuX = event.clientX;
            this.contextMenuY = event.clientY;
            this.contextMenuVisible = true;
        },

        openUpdateForm() {
            this.contextMenuVisible = false;
            if (this.contextMenuType === 'fixes') {
                this.afficherFormulaireUpdate = true;
            } else {
                this.afficherFormulaireUpdateMobile = true;
            }
        },

        openDeleteForm() {
            this.contextMenuVisible = false;
            this.afficherFormulaireDelete = true;
        },

        resetFormFixes() {
            this.nom_ferie  = '';
            this.event_date = '';
            this.date_debut = '';
            this.date_fin   = '';
        },


//feries fixes
        // get ferie
        getFeries: function () {
            axios.get('../../api/feries/fixes/get_all_feries_fixes.php')
                .then(response => { this.feries = Array.isArray(response.data) ? response.data : []; })
                .catch(err => console.error('Erreur chargement fériés fixes :', err));
        },

        //create ferie
        createFerie: function () {
            const contact = {
                nom_ferie: this.nom_ferie,
                event_date: `1900-${this.event_month}-${String(this.event_day).padStart(2, '0')}`,
                date_debut: this.date_debut,
                date_fin: this.date_fin ? this.date_fin : null,
                legal: this.legal ? 1 : 0
            };

            axios.post('../../api/feries/fixes/post_ferie_fixe.php', JSON.stringify(contact), {
                headers: { 'Content-Type': 'application/json' }
            })
                .then(response => {
                    alert('Ferie Fixe Enregistré');
                    this.afficherFormulaireAjout = false;
                    this.resetFormFixes();
                    this.getFeries();
                })
                .catch(response => {
                    alert('Problème d\'enregistrement');
                    console.log(response);
                });
        },

        //Update ferie
        modFerie: function () {
            const contact = {
                id_ferie: this.selectedFerie.id_ferie,
                nom_ferie: this.selectedFerie.nom_ferie,
                event_date: `1900-${this.selectedFerie.event_month}-${String(this.selectedFerie.event_day).padStart(2, '0')}`,
                date_debut: this.selectedFerie.date_debut,
                date_fin: this.selectedFerie.date_fin ? this.selectedFerie.date_fin : null,
                legal: this.selectedFerie.legal ? 1 : 0
            };

            axios.put('../../api/feries/fixes/put_ferie_fixe.php', JSON.stringify(contact), {
                headers: {
                    'Content-Type': 'application/json',
                }
            })
                .then(response => {
                    alert('Ferie Actualise');
                    this.afficherFormulaireUpdate = false;
                    this.getFeries();
                })
                .catch(response => {
                    alert('Probleme d\'enregistrement');
                    console.log(response);
                });
        },

// feries mobiles

        getFeriesMobiles() {
            axios.get('../../api/feries/mobiles/get_all_feries_mobiles.php')
                .then(response => { this.feriesMobiles = Array.isArray(response.data) ? response.data : []; })
                .catch(err => console.error('Erreur chargement fériés mobiles :', err));
        },

        createFerieMobile() {
            const payload = {
                nom_ferie:      this.nom_ferie_mobile,
                decalage_jours: parseInt(this.decalage_jours, 10),
                date_debut:     this.date_debut_mobile,
                date_fin:       this.date_fin_mobile || null,
                legal:          this.legal ? 1 : 0
            };
            axios.post('../../api/feries/mobiles/post_ferie_mobile.php', JSON.stringify(payload), {
                headers: { 'Content-Type': 'application/json' }
            })
                .then(() => {
                    alert('Férié mobile enregistré.');
                    this.afficherFormulaireAjoutMobile = false;
                    this.resetFormMobiles();
                    this.getFeriesMobiles();
                })
                .catch(err => {
                    alert('Erreur d\'enregistrement.');
                    console.error(err);
                });
        },

        modFerieMobile() {
            const payload = {
                id_ferie:       this.selectedFerieMobile.id_ferie,
                nom_ferie:      this.selectedFerieMobile.nom_ferie,
                decalage_jours: parseInt(this.selectedFerieMobile.decalage_jours, 10),
                date_debut:     this.selectedFerieMobile.date_debut,
                date_fin:       this.selectedFerieMobile.date_fin || null,
                legal:          this.selectedFerieMobile.legal ? 1 : 0
            };
            axios.put('../../api/feries/mobiles/put_ferie_mobile.php', JSON.stringify(payload), {
                headers: { 'Content-Type': 'application/json' }
            })
                .then(response => {
                    alert('Ferie Actualise');
                    this.afficherFormulaireUpdateMobile = false;
                    this.getFeriesMobiles();
                })
                .catch(response => {
                    alert('Probleme d\'enregistrement');
                    console.log(response);
                });
        },

// shared
        deleteFerie() {
            if (this.contextMenuType === 'fixes') {
                axios.put('../../api/feries/fixes/delete_ferie_fixe.php',
                    { id_ferie: this.selectedFerie.id_ferie },
                    { headers: { 'Content-Type': 'application/json' } }
                )
                    .then(() => {
                        this.afficherFormulaireDelete = false;
                        this.getFeries();
                    })
                    .catch(err => console.error(err));
            } else {
                axios.put('../../api/feries/mobiles/delete_ferie_mobile.php',
                    { id_ferie: this.selectedFerieMobile.id_ferie },
                    { headers: { 'Content-Type': 'application/json' } }
                )
                    .then(() => {
                        this.afficherFormulaireDelete = false;
                        this.getFeriesMobiles();
                    })
                    .catch(err => console.error(err));
            }
        },

    },
    watch: {
        event_month(newMonth) {
            const max = this.maxDayForMonth(newMonth);
            if (this.event_day && Number(this.event_day) > max) {
                this.event_day = String(max);
            }
        },
        'selectedFerie.event_month'(newMonth) {
            const max = this.maxDayForMonth(newMonth);
            if (this.selectedFerie.event_day && Number(this.selectedFerie.event_day) > max) {
                this.selectedFerie.event_day = String(max);
            }
        },
    },
})
    .component('app-menu', AppMenu)
    .mount('#app');