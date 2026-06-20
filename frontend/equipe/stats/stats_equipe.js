/* global Vue, axios, Handsontable */
const MONTHS = ['','Janvier','Février','Mars','Avril','Mai','Juin', 'Juillet','Août','Septembre','Octobre','Novembre','Décembre'];

Vue.createApp({
    data() {
        return {
            id_equipe: null,
            connectedTravailleur: null,

            travailleurs: [],
            stats: [],

            annee: new Date().getFullYear(),
            currentYear: new Date().getFullYear(),
            chart: null,
        };
    },

    computed: {
        isAdmin() { return this.connectedTravailleur.privileges === 'admin' },
        isManager() { return ['admin', 'contremaitre/manager'].includes(this.connectedTravailleur.privileges) },
        isChef() { return ['admin', 'contremaitre/manager', 'chef_equipe'].includes(this.connectedTravailleur.privileges) },
    },

    watch: {
        annee(val) {
            if (val <= this.currentYear) this.fetchStats();
        },
        async stats(newVal) {
            if (!newVal.length) {
                this.chart?.destroy();
                this.chart = null;
                return;
            }
            await this.$nextTick();
            this.createChart();
        },
    },

    async mounted() {
        const params = new URLSearchParams(window.location.search);
        const user = localStorage.getItem('connectedTravailleur');

        if (user) {
            this.connectedTravailleur = JSON.parse(user);
            this.id_equipe = params.get('id');
        }

        document.getElementById('year-prev').addEventListener('click', () => this.annee--);
        document.getElementById('year-next').addEventListener('click', () => {
            if (this.annee < this.currentYear) this.annee++;
        });

        await this.fetchTravailleurs();
        await this.fetchStats();
    },

    methods: {
        async fetchTravailleurs() {
            try {
                const { data } = await axios.get('../../../api/equipe/travailleur/get_travailleurs_by_equipe.php', {
                    params: { id_equipe: this.id_equipe }
                });
                this.travailleurs = Array.isArray(data) ? data : [];
            } catch (err) {
                console.error('fetchTravailleurs:', err);
            }
        },

        async fetchStats() {
            const accumByMois = {};

            for (const t of this.travailleurs)
            {
            try {
                const {data} = await axios.get('../../../api/heures/get_sum_and_stat_heures_by_id_travailleur.php', {
                    params: {
                        id_travailleur: t.id_travailleur,
                        annee: this.annee
                    }
                });


                const rows = Array.isArray(data) ? data : [];
                for (const row of rows) {
                    const m = row.mois;
                    if (!accumByMois[m]) {
                        accumByMois[m] = {
                            mois: m,
                            total_dues:        0,
                            total_travaillees: 0,
                        };
                    }
                    const a = accumByMois[m];
                    a.total_dues         += Number(row.total_dues)         || 0;
                    a.total_travaillees  += Number(row.total_travaillees)  || 0;
                }
            } catch (err) {
                console.error(`fetchStats travailleur ${t.id_travailleur}:`, err);
            }}
            this.stats = Object.values(accumByMois).sort((a, b) => a.mois - b.mois);
        },

        createChart() {
            const labels = this.stats.map(s => `${MONTHS[s.mois]}`);
            const travaillees = this.stats.map(s => s.total_travaillees);
            const dues = this.stats.map(s => s.total_dues);

            this.chart?.destroy(); // avoid duplicate if called again

            this.chart = new Chart(document.getElementById('myChart'), {
                type: 'line',
                data: {
                    labels,
                    datasets: [
                        {
                            label: 'Heures prestées',
                            backgroundColor: 'rgb(59,130,246)',
                            data: travaillees,
                        },
                        {
                            label: 'Heures dues',
                            backgroundColor: 'rgb(249,115,22)',
                            data: dues,
                        }
                    ]
                },
                options: {
                    responsive: true,
                    maintainAspectRatio: false,
                    plugins: {
                        legend: { display: true }
                    },
                    scales: {
                        y: { beginAtZero: true }
                    }
                }
            });
        },

        goToProfil(id) {
                window.location.href = `../page_equipe.html?id=${id}`;
        },
        goToDetailStats(id) {
            window.location.href = `./extraStats_equipe.html?id=${id}`;
        },
    }
})
    .component('app-menu', AppMenu)
    .mount('#app');