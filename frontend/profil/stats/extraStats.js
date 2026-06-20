/* global Vue, axios, Chart */

const MONTHS = ['','Janvier','Février','Mars','Avril','Mai','Juin',
    'Juillet','Août','Septembre','Octobre','Novembre','Décembre'];

Vue.createApp({
    data() {
        return {
            id_travailleur: null,
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
            if (val >= 1900 && val <= this.currentYear) this.fetchStats();
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

    mounted() {
        const params = new URLSearchParams(window.location.search);
        const user   = localStorage.getItem('connectedTravailleur');

        if (user) {
            this.connectedTravailleur = JSON.parse(user);
            this.id_travailleur = params.get('id') ?? this.connectedTravailleur.id_travailleur;
        } else {
            this.id_travailleur = params.get('id');
        }

        this.fetchStats();
    },

    methods: {
        async fetchStats() {
            try {
                const { data } = await axios.get('../../../api/heures/get_sum_and_stat_heures_by_id_travailleur.php', {
                    params: { id_travailleur: this.id_travailleur, annee: this.annee }
                });
                this.stats = Array.isArray(data) ? data : [];
            } catch (err) {
                console.error(err);
            }
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
            if (next >= 1900 && next <= this.currentYear) this.annee = next;
        },

        goTo(page) {
            const pageMap = { stats: 'stats.html', profil:'../profil.html'};
            window.location.href = `${pageMap[page]}?id=${this.id_travailleur}`;
        },
    }
})
    .component('app-menu', AppMenu)
    .mount('#app');