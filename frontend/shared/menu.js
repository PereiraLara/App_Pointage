/* global Vue */

const AppMenu = {
    props: {
        user: { type: Object, default: () => ({}) }
    },
    data() {
        return {
            mobileOpen: false
        }
    },
    computed: {
        isAdmin()   { return this.user?.privileges === 'admin' },
        isManager() { return ['admin', 'contremaitre/manager'].includes(this.user?.privileges) },
        isChef()    { return ['admin', 'contremaitre/manager', 'chef_equipe'].includes(this.user?.privileges) },

        links() {
            const canChef = this.isChef || this.isManager || this.isAdmin;
            return [
                { id: 'travailleurs', show: canChef,     href: '/php_SGBD/frontend/travailleur/travailleurs.html', icon: 'icofont-ui-user-group', label: 'Travailleurs' },
                { id: 'equipes',      show: canChef,     href: '/php_SGBD/frontend/equipe/equipes.html',           icon: 'icofont-people',         label: 'Equipes' },
                { id: 'calendrier',   show: canChef,     href: '/php_SGBD/frontend/heures/calendrier.html',        icon: 'icofont-calendar',       label: 'Calendrier' },
                { id: 'codes',        show: this.isAdmin, href: '/php_SGBD/frontend/codes/codes.html',             icon: 'icofont-archive',        label: 'Codes' },
                { id: 'feries',       show: this.isAdmin, href: '/php_SGBD/frontend/feries/feries.html',           icon: 'icofont-library',        label: 'Feries' },
                { id: 'profil',       show: true,         href: '/php_SGBD/frontend/profil/profil.html',           icon: 'icofont-ui-user',        label: 'Profil' },
            ];
        }
    },
    template: `
        <nav class="-m-4 mb-4 bg-lime-100 relative z-30 lg:h-12">
            <div class="flex items-center px-4 py-3 lg:h-12 lg:py-0">
                <!-- Hamburger toggle, mobile only -->
                <button type="button"
                        @click="mobileOpen = !mobileOpen"
                        class="md:hidden p-2 -mr-2 text-2xl leading-none"
                        :aria-expanded="mobileOpen ? 'true' : 'false'"
                        aria-label="Ouvrir le menu">
                    <i :class="mobileOpen ? 'icofont-close-line-circled' : 'icofont-navigation-menu'"></i>
                </button>

                <!-- Inline links, desktop/tablet only -->
                <div class="lg:h-12 hidden md:flex md:flex-1 md:items-center md:justify-between md:gap-1">
                    <template v-for="link in links" :key="'d-' + link.id">
                        <a v-show="link.show"
                           :href="link.href"
                           class="flex items-center gap-1 px-3 py-2 lg:py-0 rounded font-bold whitespace-nowrap hover:bg-lime-200 lg:text-lg">
                            <i :class="link.icon"></i> {{ link.label }}
                        </a>
                    </template>
                </div>
            </div>

            <!-- Dropdown links, mobile only -->
            <div v-show="mobileOpen" class="md:hidden border-t border-lime-300">
                <template v-for="link in links" :key="'m-' + link.id">
                    <a v-show="link.show"
                       :href="link.href"
                       @click="mobileOpen = false"
                       class="flex items-center gap-3 px-4 py-3 font-bold border-b border-lime-200 active:bg-lime-200">
                        <i :class="link.icon" class="text-lg"></i> {{ link.label }}
                    </a>
                </template>
            </div>
        </nav>
    `
};