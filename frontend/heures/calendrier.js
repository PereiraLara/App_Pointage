// ── State ────────────────────────────────────────────────────────────────────
let date = new Date();
let year = date.getFullYear();
let month = date.getMonth();
let codes = [];
let joursFeries = [];
let hot = null;
let modifiedCells = [];

const connectedTravailleur = JSON.parse(localStorage.getItem('connectedTravailleur') ?? 'null') ?? {};

// ── DOM refs ─────────────────────────────────────────────────────────────────
const dayList    = document.querySelector('.calendar-dates');
const currDate = document.querySelector('.calendar-current-date');

// ── Calendar ─────────────────────────────────────────────────────────────────
function daysInMonth(y, m) { return new Date(y, m + 1, 0).getDate(); }

function renderCalendar() {
    const firstDay  = new Date(year, month, 1).getDay();
    const lastDay   = new Date(year, month, daysInMonth(year, month)).getDay();
    const prevTotal = new Date(year, month, 0).getDate();
    const today     = new Date();

    const prev = Array.from({ length: firstDay },
        (_, i) => `<li class="inactive text-gray-400">${prevTotal - firstDay + i + 1}</li>`);

    const curr = Array.from({ length: daysInMonth(year, month) }, (_, i) => {
        const d = i + 1;
        const isToday = d === today.getDate() && month === today.getMonth() && year === today.getFullYear();
        const isFerie   = joursFeries.includes(d);
        const classes   = [
            isToday ? 'active font-bold' : '',
            isFerie ? 'bg-gray-300 cursor-not-allowed' : 'lg:cursor-pointer'
        ].filter(Boolean).join(' ');
        return `<li class="${classes}" data-day="${d}" data-ferie="${isFerie}">${d}</li>`;
    });

    const next = Array.from({ length: 6 - lastDay },
        (_, i) => `<li class="inactive text-gray-400">${i + 1}</li>`);

    currDate.value = `${year}-${String(month + 1).padStart(2, '0')}`;
    dayList.innerHTML  = [...prev, ...curr, ...next].join('');

    dayList.querySelectorAll('li:not(.inactive)').forEach(li => {
        if (li.dataset.ferie === 'true') return;
        li.addEventListener('click', () => {
            const { id_travailleur } = connectedTravailleur;
            window.location.href = `heures_du_jour.html?id_travailleur=${id_travailleur}&jour=${li.dataset.day}&mois=${month + 1}&annee=${year}`;
        });
    });
}

currDate.addEventListener('change', () => {
    const [y, m] = currDate.value.split('-').map(Number);
    year  = y;
    month = m - 1;
    renderCalendar();
    loadEncodageMois();
});

document.querySelectorAll('#calendar-prev, #calendar-next').forEach(btn => {
    btn.addEventListener('click', () => {
        month += btn.id === 'calendar-next' ? 1 : -1;
        if (month < 0)  { month = 11; year--; }
        if (month > 11) { month = 0;  year++; }
        renderCalendar();
        loadEncodageMois();
    });
});

// ── Helpers ───────────────────────────────────────────────────────────────────
const isValidValue = v => {
    if (v === '') return true;
    if (codes.includes(v)) return true;
    const n = parseFloat(v);
    return !isNaN(n) && n >= 0 && n <= 11;
};

const colIndexForDay = d => d + 1;
const dayColIndex = d => d + 1;

async function loadJoursFeries() {
    try {
        const { data } = await axios.get('../../api/feries/get_all_feries_actifs.php', {
            params: { mois: month + 1, annee: year }
        });
        joursFeries = Array.isArray(data.jours) ? data.jours : [];
    } catch (err) {
        console.error('Could not load jours fériés:', err);
        joursFeries = [];
    }
}

// ── Table ─────────────────────────────────────────────────────────────────────
async function loadEncodageMois() {
    const mois = month + 1;
    const days = daysInMonth(year, month);

    try {
        const isManager = ['admin', 'contremaitre/manager'].includes(connectedTravailleur.privileges);
        const travailleursUrl = isManager
            ? '../../api/travailleur/get_all_travailleurs_actifs.php'
            : '../../api/travailleur/chef_equipe/get_all_travailleur_by_chef_equipe.php';
        const travailleursParams = isManager
            ? {}
            : { id_travailleur: connectedTravailleur.id_travailleur, jour: 1, mois, annee: year };

        const [{ data: travailleurs }, { data: heures }] = await Promise.all([
            axios.get(travailleursUrl, { params: travailleursParams }),
            axios.get('../../api/heures/get_all_heures_by_month.php', {
                params: { id_travailleur: connectedTravailleur.id_travailleur, mois, annee: year }
            }),

            loadJoursFeries()
        ]);

        renderCalendar();

        const safeTravailleurs = Array.isArray(travailleurs)
            ? travailleurs.filter(t => String(t.id_travailleur) !== String(connectedTravailleur.id_travailleur))
            : [];
        const safeHeures = Array.isArray(heures) ? heures : [];

        const tableData = safeTravailleurs.map(w => {
            const wHeures = safeHeures.find(h => h.id_travailleur == w.id_travailleur);
            const row = { id: w.id_travailleur, nom: w.nom };
            for (let d = 1; d <= days; d++) row[d] = wHeures?.[d] ?? '';
            return row;
        });

        const dayColumn = d => ({
            data: `${d}`, type: 'dropdown', source: codes,
            strict: false, filter: true, allowInvalid: true,
            readOnly: joursFeries.includes(d),
            validator: (value, cb) => cb(isValidValue(String(value ?? '').trim()))
        });

        const hotColumns = [
            { data: 'id',  type: 'numeric', readOnly: true },
            { data: 'nom', type: 'text',    readOnly: true },
            ...Array.from({ length: days }, (_, i) => dayColumn(i + 1))
        ];

        const colHeaders = [
            'ID', 'Nom',
            ...Array.from({ length: days }, (_, i) => {
                const d = i + 1;
                return joursFeries.includes(d) ? `<span class="text-gray-400">${d}</span>` : `${d}`;
            })
        ];

        hot?.destroy();
        hot = new Handsontable(document.getElementById('encodageMois'), {
            data: tableData,
            rowHeaders: false,
            colHeaders,
            columns: hotColumns,
            width: '100%', height: 350,
            stretchH: 'none', manualColumnResize: true,
            contextMenu: false, fixedColumnsStart: 2,
            licenseKey: 'non-commercial-and-evaluation',
            theme: 'ht-theme-horizon',
            className: 'htCenter htMiddle',
            cells(row, col) {
                const day = col - 1;
                if (col >= 2 && joursFeries.includes(day)) {
                    return { readOnly: true, className: 'htCenter htMiddle jour-ferie' };
                }
                return {};
            },
            afterGetColHeader(col, TH) {
                const day = col - 1;
                if (col >= 2 && joursFeries.includes(day)) {
                    TH.classList.add('jour-ferie');
                } else {
                    TH.classList.remove('jour-ferie');
                }
            },
            afterChange(changes, source) {
                if (source === 'loadData' || !changes) return;
                changes.forEach(([row, prop, , value]) =>
                {
                    if (joursFeries.includes(parseInt(prop))) return;
                    modifiedCells.push({ row, prop, value });

                });
            }
        });

    } catch (err) {
        console.error(err);
    }
}

// ── Save ──────────────────────────────────────────────────────────────────────
async function setHeures() {
    hot.getActiveEditor()?.finishEditing();

    const allRows = hot.getSourceData();
    const days = daysInMonth(year, month);
    const erreurs = [];

    allRows.forEach(worker => {
        for (let d = 1; d <= days; d++) {
            if (joursFeries.includes(d)) continue;
            const v = String(worker[d] ?? '').trim();
            if (v && !isValidValue(v)) erreurs.push({ travailleur: worker.nom, jour: d, valeur: v });
        }
    });

    try {
        await Promise.allSettled(
            modifiedCells
                .filter(c => isValidValue(String(c.value ?? '').trim()))
                .map(c => {
                    const row = hot.getSourceDataAtRow(c.row);
                    return axios.post('../../api/heures/post_heures.php', {
                        id_travailleur: row.id,
                        mois: month + 1, annee: year,
                        jour: parseInt(c.prop), valeur: c.value
                    });
                })
        );

        modifiedCells = [];

        alert(erreurs.length
            ? `Sauvegardé avec ${erreurs.length} erreur(s).\n\n` +
            erreurs.map(e => `${e.travailleur} - jour ${e.jour} : ${e.valeur}`).join('\n')
            : 'Sauvegardé'
        );

    } catch (err) {
        console.error(err);
    }
}

// ── Init ──────────────────────────────────────────────────────────────────────
async function loadCodes() {
    try {
        const { data } = await axios.get('../../api/codes/get_all_codes_actifs.php');
        codes = data.map(c => c.nom_code);
    } catch (err) {
        console.error(err);
    }
}

(async () => {
    await loadCodes();
    renderCalendar();
    await loadEncodageMois();
})();

/* global Vue, axios */
Vue.createApp({ data() { return { connectedTravailleur } } })
    .component('app-menu', AppMenu)
    .mount('#menu-app');