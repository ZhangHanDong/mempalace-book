// Language switcher for bilingual mdbook
// Works in both local dev (different ports) and deployed (path-based) modes
(() => {
    const rightButtons = document.querySelector('.right-buttons');
    if (!rightButtons) return;

    const loc = window.location;
    const isLocal = loc.protocol === 'file:' || loc.hostname === 'localhost' || loc.hostname === '127.0.0.1';

    // Detect current language from <html lang="..."> set by mdbook
    const htmlLang = document.documentElement.lang || 'zh';
    const isEnglish = htmlLang === 'en';

    let targetUrl;

    if (isLocal && loc.port) {
        // Local dev: toggle between ports
        // Convention: Chinese port = N, English port = N+1
        const currentPort = parseInt(loc.port, 10);
        const targetPort = isEnglish ? currentPort - 1 : currentPort + 1;
        targetUrl = `${loc.protocol}//${loc.hostname}:${targetPort}${loc.pathname}${loc.search}${loc.hash}`;
    } else {
        // Deployed: toggle /en/ in path
        const segments = loc.pathname.split('/').filter(Boolean);
        const enIdx = segments.indexOf('en');

        if (isEnglish && enIdx >= 0) {
            // English → Chinese: remove /en/
            segments.splice(enIdx, 1);
        } else if (!isEnglish) {
            // Chinese → English: insert /en/ after site root
            // Find the position after the site-url base path
            const firstContentIdx = segments.findIndex(s =>
                s.endsWith('.html') || s === 'print.html' ||
                /^(preface|ch\d|part\d|appendix|index)/.test(s)
            );
            const insertIdx = firstContentIdx >= 0 ? firstContentIdx : segments.length;
            segments.splice(insertIdx, 0, 'en');
        }

        const trailingSlash = loc.pathname.endsWith('/');
        targetUrl = `/${segments.join('/')}${trailingSlash ? '/' : ''}${loc.search}${loc.hash}`;
    }

    // Create the button
    const link = document.createElement('a');
    link.className = 'icon-button language-switcher-button';
    link.href = targetUrl;
    link.title = isEnglish ? 'Switch to Chinese' : 'Switch to English';
    link.setAttribute('aria-label', link.title);

    const label = document.createElement('span');
    label.className = 'language-switcher-label';
    label.textContent = isEnglish ? '中文' : 'EN';
    link.appendChild(label);

    rightButtons.insertBefore(link, rightButtons.firstChild);
})();
