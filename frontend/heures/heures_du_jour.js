/* global Vue, axios */

Vue.createApp({
    data() {
        return {
            day: '',
            month: '',
            year: '',
            codes: [],
            isFerie: false,

            travailleurs: [],
            connectedTravailleur: {
                id_travailleur: '',
                nom: '',
                email: '',
                privileges: ''
            },
        }
    },

    computed: {
        isAdmin() {
            return this.connectedTravailleur.privileges === 'admin'
        },
        isManager() {
            return ['admin', 'contremaitre/manager'].includes(this.connectedTravailleur.privileges)
        },
        isChef() {
            return ['admin', 'contremaitre/manager', 'chef_equipe'].includes(this.connectedTravailleur.privileges)
        },

        // date du jour
        dateParam() {
            if (!this.year || !this.month || !this.day) return '';
            return `${this.year}-${String(this.month).padStart(2, '0')}-${String(this.day).padStart(2, '0')}`;
        }
    },
    mounted() {
        // récupérer date depuis URL
        const params = new URLSearchParams(window.location.search);

        const user = localStorage.getItem('connectedTravailleur');
        if(user){
            this.connectedTravailleur = JSON.parse(user);
        }

        this.day = params.get('jour');
        this.month = params.get('mois');
        this.year = params.get('annee');

        // récupérer travailleurs
        this.getTravailleurs();
        // récupérer codes
        this.getCodes();
        // vérifier si jour férié
        this.checkFerie();
    },

    methods: {
        async setHeures() {
            const results = await Promise.allSettled(
                this.travailleurs.map(t => this.setHeure(t))
            );

            const erreurs = results
                .map((r, i) => ({ r, t: this.travailleurs[i] }))
                .filter(({ r }) => r.status === 'rejected' || r.value?.invalid)
                .map(({ r, t }) =>
                    r.status === 'rejected'
                        ? `${t.nom} : erreur d'enregistrement`
                        : `${t.nom} : code invalide ("${t.jour}")`
                );

            alert(erreurs.length
                ? `Sauvegardé avec ${erreurs.length} erreur(s) :\n\n${erreurs.join('\n')}`
                : 'Heures enregistrées'
            );
        },

        // charger travailleurs
        getTravailleurs() {
            const isManager = ['admin', 'contremaitre/manager'].includes(this.connectedTravailleur.privileges);
            const url = isManager
                ? '../../api/travailleur/get_all_travailleurs_actifs.php'
                : '../../api/travailleur/chef_equipe/get_all_travailleur_by_chef_equipe.php';
            const params = isManager
                ? {}
                : { id_travailleur: this.connectedTravailleur.id_travailleur, jour: this.day, mois: this.month, annee: this.year };

            axios.get(url, { params })
                .then(response => {
                    const travailleurs = response.data
                        .filter(t => String(t.id_travailleur) !== String(this.connectedTravailleur.id_travailleur));

                    // Charger les heures existantes pour ce mois
                    return axios.get('../../api/heures/get_all_heures_by_month.php', {
                        params: { mois: this.month, annee: this.year }
                    }).then(heuresRes => {
                        const heuresMap = {};
                        (heuresRes.data ?? []).forEach(row => {
                            heuresMap[String(row.id_travailleur)] = row;
                        });

                        this.travailleurs = travailleurs.map(t => ({
                            ...t,
                            jour: heuresMap[String(t.id_travailleur)]?.[this.day] ?? ''
                        }));
                    });
                })
                .catch(console.error);

        },

        // charger codes
        getCodes() {
            const params = this.dateParam ? { date: this.dateParam } : {};
            axios.get('../../api/codes/get_all_codes_actifs.php')
                .then((response) => {
                    this.codes = Array.isArray(response.data) ? response.data : [];
                })
                .catch((error) => {
                    console.error(error);
                });
        },

        // sauver heures
        setHeure(travailleur) {
            // vérifier si le code existe
            const codeTrouve = this.codes.find(
                code => code.nom_code === travailleur.jour
            );

            // vérifier si c'est un nombre d'heures
            const heures = parseFloat(travailleur.jour);

            if(!codeTrouve && travailleur.jour != '' && !(heures >= 0 && heures <= 11))
            {
                return Promise.resolve({ invalid: true });
            }

            const contact = {
                id_travailleur: travailleur.id_travailleur,
                mois: this.month,
                annee: this.year,
                jour: this.day,
                valeur: travailleur.jour
            };

            return axios.post('../../api/heures/post_heures.php', JSON.stringify(contact),
                {
                    headers: {'Content-Type': 'application/json'}
                }
            );
        },

        async checkFerie() {
            try {
                const { data } = await axios.get('../../api/ferie/get_all_feries_actifs.php', {
                    params: { mois: this.month, annee: this.year }
                });
                this.isFerie = (data.jours ?? []).includes(Number(this.day));
            } catch (err) {
                console.error(err);
                this.isFerie = false;
            }
        },

        navigateTo(y, m, d) {
            this.year  = y;
            this.month = m;
            this.day   = d;
            window.history.replaceState({}, '',
                `${window.location.pathname}?id_travailleur=${this.connectedTravailleur.id_travailleur}&jour=${d}&mois=${m}&annee=${y}`
            );
            this.travailleurs = [];
            this.isFerie = false;
            this.getTravailleurs();
            this.checkFerie();
        },

        changeDay(step) {
            const d = new Date(this.year, this.month - 1, this.day);
            d.setDate(d.getDate() + step);
            this.navigateTo(d.getFullYear(), d.getMonth() + 1, d.getDate());
        },

        jumpToDate(val) {
            const [y, m, d] = val.split('-').map(Number);
            this.navigateTo(y, m, d);
        },

    }
})
    .component('app-menu', AppMenu)
    .mount('#app');