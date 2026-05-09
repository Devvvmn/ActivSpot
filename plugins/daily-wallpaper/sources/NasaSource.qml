import QtQuick

QtObject {
    id: root

    function getNasaPrimaryImageUrl(page) {
        let match = page.match(/<[^>]*class="[^"]*hds-gallery-image[^"]*"[^>]*>[\s\S]*?<img[^>]*src="([^"]+)"/i);
        if (!match) {
            match = page.match(/<img[^>]*class="[^"]*hds-gallery-image[^"]*"[^>]*src="([^"]+)"/i);
        }
        return match ? match[1] : "";
    }

    function getNasaFallbackImageUrl(page) {
        let match = page.match(/<meta\s+property="og:image"\s+content="([^"]+)"/i);
        if (!match) {
            match = page.match(/<meta\s+name="twitter:image"\s+content="([^"]+)"/i);
        }
        return match ? match[1] : "";
    }

    function resolveDownload(_locale, httpGet) {
        const page = httpGet("https://www.nasa.gov/image-of-the-day/");
        const primaryUrl = getNasaPrimaryImageUrl(page);
        const fallbackUrl = getNasaFallbackImageUrl(page);

        if (!primaryUrl && !fallbackUrl) {
            throw new Error("Failed to parse NASA image URL");
        }

        return {
            prefix: "nasa",
            primaryUrl: primaryUrl,
            fallbackUrl: fallbackUrl
        };
    }
}
