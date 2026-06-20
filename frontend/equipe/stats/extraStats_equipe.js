/* global Vue, axios, Chart */

const MONTHS = ['','Janvier','Février','Mars','Avril','Mai','Juin',
    'Juillet','Août','Septembre','Octobre','Novembre','Décembre'];

Vue.createApp({
    data() {
        return {
            id_equipe: null,
            id_travailleur: null,

            travailleurs: [],
            stats: [],

            annee: new Date().getFullYear(),
            currentYear: new Date().getFullYear(),
            chart: null,
            MONTHS,

            connectedTravailleur: {
                id_travailleur: '',
                nom: '',
                email: '',
                privileges: ''
            },
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
        stats(newVal) {
            if (!newVal.length) {
                this.chart?.destroy();
                this.chart = null;
                return;
            }
            this.$nextTick(() => this.createChart());
        }
    },

    async mounted() {
        const params = new URLSearchParams(window.location.search);
        const user = localStorage.getItem('connectedTravailleur');

        if (user) {
            this.connectedTravailleur = JSON.parse(user);
            this.id_equipe = params.get('id');
        }

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
                                heures_numeriques: 0,
                                difference:        0,
                                jours_prestes:     0,
                                jours_conge:       0,
                                jours_maladie:     0,
                                jours_chomage:     0,
                                jours_accident:    0,
                                jours_recuperation:0,
                                jours_absence:     0,
                                autre:             0,
                            };
                        }
                        const a = accumByMois[m];
                        a.total_dues         += Number(row.total_dues)         || 0;
                        a.total_travaillees  += Number(row.total_travaillees)  || 0;
                        a.heures_numeriques  += Number(row.heures_numeriques)  || 0;
                        a.difference         += Number(row.difference)         || 0;
                        a.jours_prestes      += Number(row.jours_prestes)      || 0;
                        a.jours_conge        += Number(row.jours_conge)        || 0;
                        a.jours_maladie      += Number(row.jours_maladie)      || 0;
                        a.jours_chomage      += Number(row.jours_chomage)      || 0;
                        a.jours_accident     += Number(row.jours_accident)     || 0;
                        a.jours_recuperation += Number(row.jours_recuperation) || 0;
                        a.jours_absence      += Number(row.jours_absence)      || 0;
                    a.autre                  += Number(row.autre)              || 0;
                    }
                } catch (err) {
                    console.error(`fetchStats travailleur ${t.id_travailleur}:`, err);
                }}
            this.stats = Object.values(accumByMois).sort((a, b) => a.mois - b.mois);
        },

        yearlyTotal(field) {
            const total = this.stats.reduce((sum, s) => sum + (s[field] ?? 0), 0);
            return Math.round(total * 100) / 100;
        },

        createChart() {
            this.chart?.destroy();
            this.chart = new Chart(document.getElementById('stackedChart'), {
                type: 'bar',
                data: {
                    labels: this.stats.map(s => MONTHS[s.mois]),
                    datasets: [
                        { label: 'Prestés',   backgroundColor: 'rgb(59,130,246)',  data: this.stats.map(s => s.jours_prestes) },
                        { label: 'Congés',    backgroundColor: 'rgb(34,197,94)',   data: this.stats.map(s => s.jours_conge) },
                        { label: 'Maladie',   backgroundColor: 'rgb(250,204,21)',  data: this.stats.map(s => s.jours_maladie) },
                        { label: 'Chômage',   backgroundColor: 'rgb(249,115,22)',  data: this.stats.map(s => s.jours_chomage) },
                        { label: 'Accident',  backgroundColor: 'rgb(239,68,68)',   data: this.stats.map(s => s.jours_accident) },
                        { label: 'Récup.',    backgroundColor: 'rgb(168,85,247)',  data: this.stats.map(s => s.jours_recuperation) },
                        { label: 'Absences',  backgroundColor: 'rgb(107,114,128)', data: this.stats.map(s => s.jours_absence) },
                        { label: 'Autre',     backgroundColor: 'rgb(50,52,57)',    data: this.stats.map(s => s.autre) },
                    ]
                },
                options: {
                    responsive: true,
                    maintainAspectRatio: false,
                    scales: {
                        x: { stacked: true },
                        y: { stacked: true, beginAtZero: true, title: { display: true, text: 'Jours' } }
                    },
                    plugins: { legend: { display: true, position: 'bottom' } }
                }
            });
        },

        changeYear(step) {
            const next = this.annee + step;
            if (next <= this.currentYear) this.annee = next;
        },

        goTo(page) {
            const pageMap = { stats: 'stats_equipe.html', profil: '../page_equipe.html'};
            window.location.href = `${pageMap[page]}?id=${this.id_equipe}`;
        },
    }
})
    .component('app-menu', AppMenu)
    .mount('#app');