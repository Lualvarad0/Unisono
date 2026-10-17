import { useEffect, useState } from "react";

interface ReleaseInfo {
  apkUrl: string;
  label: string;
}

const REPO = "Lualvarad0/Unisono";
const FALLBACK: ReleaseInfo = {
  apkUrl: `https://github.com/${REPO}/releases/latest`,
  label: "Ver todas las versiones en GitHub",
};

/**
 * Busca el último release en GitHub y el .apk adjunto — el botón de
 * descarga arranca apuntando a la página de Releases (fallback seguro)
 * y se actualiza solo apenas resuelve, sin tocar este archivo en cada
 * versión nueva. Ver también la versión vanilla-JS que reemplaza, en
 * el `public/index.html` anterior.
 */
export function useLatestRelease(): ReleaseInfo {
  const [release, setRelease] = useState<ReleaseInfo>(FALLBACK);

  useEffect(() => {
    let cancelado = false;
    (async () => {
      try {
        const res = await fetch(`https://api.github.com/repos/${REPO}/releases/latest`);
        if (!res.ok) throw new Error("sin respuesta");
        const datos = await res.json();
        const apk = (datos.assets ?? []).find((a: { name: string }) =>
          a.name.endsWith(".apk"),
        );
        if (!apk) throw new Error("sin apk adjunto");
        if (cancelado) return;
        const mb = (apk.size / (1024 * 1024)).toFixed(1);
        setRelease({
          apkUrl: apk.browser_download_url,
          label: `${datos.tag_name} · ${mb} MB`,
        });
      } catch {
        if (!cancelado) setRelease(FALLBACK);
      }
    })();
    return () => {
      cancelado = true;
    };
  }, []);

  return release;
}
