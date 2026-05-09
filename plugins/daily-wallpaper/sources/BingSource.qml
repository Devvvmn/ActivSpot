import QtQuick

QtObject {
    id: root

    function fetchBingUrlBase(locale, httpGet) {
        const response = httpGet(`https://www.bing.com/HPImageArchive.aspx?format=js&idx=0&n=1&mkt=${locale}`);
        const parsed = JSON.parse(response);
        const firstImage = parsed?.images?.[0];
        return firstImage?.urlbase || "";
    }

    function resolveDownload(locale, httpGet) {
        const urlBase = fetchBingUrlBase(locale, httpGet);
        if (!urlBase) {
            throw new Error(`Failed to extract Bing urlbase for locale ${locale}`);
        }

        return {
            prefix: "bing",
            primaryUrl: `https://www.bing.com${urlBase}_UHD.jpg`,
            fallbackUrl: `https://www.bing.com${urlBase}_1920x1080.jpg`
        };
    }
}
