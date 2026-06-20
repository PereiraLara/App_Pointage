/* global Vue, axios, Handsontable */

Vue.createApp({
    data() {
        return {
            id_travailleur: null,
            historique: [],
            connectedTravailleur: null,
            hot: null,
            annee: new Date().getFullYear(),
            currentYear: new Date().getFullYear(),
        };
    },

    computed: {
        isAdmin() { return this.connectedTravailleur.privileges === 'admin' },
        isManager() { return ['admin', 'contremaitre/manager'].includes(this.connectedTravailleur.privileges) },
        isChef() { return ['admin', 'contremaitre/manager', 'chef_equipe'].includes(this.connectedTravailleur.privileges) },
    },

    watch: {
        annee(val) {
            if (val <= this.currentYear) this.fetchHistorique();
        }
    },
    mounted() {
        const params = new URLSearchParams(window.location.search);
        const user   = localStorage.getItem('connectedTravailleur');

        if (user) {
            this.connectedTravailleur = JSON.parse(user);
            this.id_travailleur = params.get('id') ?? this.connectedTravailleur.id_travailleur;
        } else {
            this.id_travailleur = params.get('id');
        }

        document.getElementById('year-prev').addEventListener('click', () => this.annee--);
        document.getElementById('year-next').addEventListener('click', () => {
            if (this.annee < this.currentYear) this.annee++;
        });

        this.fetchHistorique();
    },

    methods: {
        async fetchHistorique() {
            try {
                const { data } = await axios.get('../../api/heures/get_all_heures_by_id_travailleur.php', {
                    params: {
                        id_travailleur: this.id_travailleur,
                        annee: this.annee
                    }
                });
                // si pas d'historique => pas crash
                this.historique = Array.isArray(data) ? data : [];
                if (this.historique.length) this.loadHeures();
                else {
                    if (this.hot) {
                        this.hot.destroy();
                        this.hot = null;
                    }
                }
            } catch (err) {
                console.error(err);
            }
        },

        loadHeures() {
            const MONTHS = ['','Janvier','Février','Mars','Avril','Mai','Juin', 'Juillet','Août','Septembre','Octobre','Novembre','Décembre'];

            // Sort newest first, map directly — one API row = one table row
            const tableData = this.historique
                // .sort((a, b) => b.mois - a.mois)
                .map(r => ({
                    mois: `${MONTHS[r.mois]}`,
                    ...Object.fromEntries(
                        Array.from({ length: 31 }, (_, i) => [i + 1, r[i + 1] ?? ''])
                    )
                }));

            const hotColumns = [
                { data: 'mois', title: 'Mois', type: 'text', readOnly: true, width: 130 },
                ...Array.from({ length: 31 }, (_, i) => ({
                    data: `${i + 1}`,
                    title: `${i + 1}`,
                    type: 'text',
                    readOnly: true,
                    width: 45,
                }))
            ];

            this.hot?.destroy();
            this.hot = new Handsontable(document.getElementById('encodageMois'), {
                data: tableData,
                rowHeaders: false,
                colHeaders: hotColumns.map(c => c.title),
                columns: hotColumns,
                width: '100%',
                height: 'auto',
                stretchH: 'none',
                manualColumnResize: true,
                contextMenu: false,
                fixedColumnsStart: 1,
                licenseKey: 'non-commercial-and-evaluation',
                theme: 'ht-theme-horizon',
                className: 'htCenter htMiddle',
                readOnly: true,
            });
        },


        goToProfil(id) {
                window.location.href = `profil.html?id=${id}`;
        },
        goToStats(id) {
            window.location.href = `stats/stats.html?id=${id}`;
        },

    }
})
    .component('app-menu', AppMenu)
    .mount('#app');