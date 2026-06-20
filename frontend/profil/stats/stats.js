/* global Vue, axios, Handsontable */

const MONTHS = ['','Janvier','Février','Mars','Avril','Mai','Juin', 'Juillet','Août','Septembre','Octobre','Novembre','Décembre'];

Vue.createApp({
    data() {
        return {
            id_travailleur: null,
            stats: [],
            connectedTravailleur: null,
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
        // refetch every time annee changes
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


    mounted() {
        const params = new URLSearchParams(window.location.search);
        const user   = localStorage.getItem('connectedTravailleur');

        if (user) {
            this.connectedTravailleur = JSON.parse(user);
            this.id_travailleur = params.get('id') ?? this.connectedTravailleur.id_travailleur;
        } else {
            this.id_travailleur = params.get('id');
        }

        // wire up arrow buttons
        document.getElementById('year-prev').addEventListener('click', () => this.annee--);
        document.getElementById('year-next').addEventListener('click', () => {
            if (this.annee < this.currentYear) this.annee++;
        });

        this.fetchStats();
    },

    methods: {
        async fetchStats() {
            try {
                const { data } = await axios.get('../../../api/heures/get_sum_and_stat_heures_by_id_travailleur.php', {
                    params: {
                        id_travailleur: this.id_travailleur,
                        annee: this.annee
                    }
                });
                this.stats = Array.isArray(data) ? data : [];
                // if (!this.stats.length) {
                //     this.chart?.destroy();
                //     this.chart = null;
                //     return;
                // }
                // await this.$nextTick(); // ensure canvas is visible before init
                // this.createChart();
            } catch (err) {
                console.error(err);
            }
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
            window.location.href = `../profil.html?id=${id}`;

        },
        goToHistorique(id) {
            window.location.href = `../historique.html?id=${id}`;

        },
        goToDetailStats(id) {
            window.location.href = `extraStats.html?id=${id}`;

        },

    }
})
    .component('app-menu', AppMenu)
    .mount('#app');