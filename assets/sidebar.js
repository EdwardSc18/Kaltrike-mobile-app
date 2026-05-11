(function () {
    var toggle = document.querySelector('[data-sidebar-toggle]');
    var sidebar = document.getElementById('appSidebar');
    var backdrop = document.querySelector('[data-sidebar-backdrop]');
    if (!toggle || !sidebar || !backdrop) {
        return;
    }
    function setOpen(isOpen) {
        sidebar.classList.toggle('is-open', isOpen);
        backdrop.classList.toggle('is-open', isOpen);
        document.body.classList.toggle('sidebar-open', isOpen && window.innerWidth <= 992);
        toggle.setAttribute('aria-expanded', isOpen ? 'true' : 'false');
    }
    toggle.addEventListener('click', function () {
        setOpen(!sidebar.classList.contains('is-open'));
    });
    backdrop.addEventListener('click', function () {
        setOpen(false);
    });
    Array.prototype.forEach.call(sidebar.querySelectorAll('a'), function (link) {
        link.addEventListener('click', function () {
            if (window.innerWidth <= 992) {
                setOpen(false);
            }
        });
    });
    window.addEventListener('resize', function () {
        if (window.innerWidth > 992) {
            setOpen(false);
        }
    });
})();
