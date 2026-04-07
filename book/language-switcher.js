(() => {
    const rightButtons = document.querySelector('.right-buttons');
    if (!rightButtons) return;

    const loc = window.location;
    const segments = loc.pathname.split('/').filter(Boolean);
    const trailingSlash = loc.pathname.endsWith('/');
    const isLocal = loc.protocol === 'file:' || loc.hostname === 'localhost' || loc.hostname === '127.0.0.1';

    // Detect if we're on the English version:
    // - Deployed: path contains '/en/'
    // - Local serve: port 3001 = English, port 3000 = Chinese
    // - book-en site-url contains '/en/'
    const pathHasEn = segments.includes('en');
    const isEnglishByPort = isLocal && loc.port === '3001';
    const isEnglish = pathHasEn || isEnglishByPort;

    const knownContentRoots = new Set([
        'appendix', 'part1', 'part2', 'part3', 'part4', 'part5', 'part6', 'part7',
        'index.html', 'preface.html', '404.html', 'print.html', 'toc.html',
    ]);

    // Local dev: switch between ports
    if (isLocal && loc.port) {
        const targetPort = isEnglish ? '3000' : '3001';
        const targetUrl = `${loc.protocol}//${loc.hostname}:${targetPort}${loc.pathname}${loc.search}${loc.hash}`;
        appendButton(targetUrl, isEnglish);
        return;
    }

    // Deployed: toggle /en/ in path
    let prefix = [];
    let rest = [];

    const enIdx = segments.indexOf('en');
    if (enIdx >= 0) {
        prefix = segments.slice(0, enIdx);
        rest = segments.slice(enIdx + 1);
    } else {
        const first = segments[0];
        const looksLikeContent = !first
            || knownContentRoots.has(first)
            || /^part\d+$/.test(first)
            || first.endsWith('.html');
        prefix = looksLikeContent ? [] : [first];
        rest = looksLikeContent ? segments : segments.slice(1);
    }

    const targetSegments = isEnglish
        ? prefix.concat(rest)
        : prefix.concat(['en'], rest);
    const targetPath = `/${targetSegments.join('/')}${trailingSlash ? '/' : ''}`;
    const targetUrl = `${targetPath}${loc.search}${loc.hash}`;

    appendButton(targetUrl, isEnglish);

    function appendButton(url, fromEnglish) {
        const link = document.createElement('a');
        link.className = 'icon-button language-switcher-button';
        link.href = url;
        link.title = fromEnglish ? 'Switch to Chinese' : 'Switch to English';
        link.setAttribute('aria-label', link.title);

        const label = document.createElement('span');
        label.className = 'language-switcher-label';
        label.textContent = fromEnglish ? '中文' : 'EN';
        link.appendChild(label);

        rightButtons.insertBefore(link, rightButtons.firstChild);
    }
})();
