export function Footer() {
  return (
    <footer className="border-t border-borde py-8 px-4">
      <div className="max-w-6xl mx-auto flex flex-wrap items-center justify-between gap-4 text-xs text-texto-tenue">
        <div className="flex flex-col gap-1">
          <p>Unísono — hecha para equipos de alabanza.</p>
          <a
            href="https://github.com/Lualvarad0/Unisono"
            target="_blank"
            rel="noopener"
            className="hover:text-texto transition-colors"
          >
            github.com/Lualvarad0/Unisono
          </a>
        </div>
        <p>
          Desarrollado por{" "}
          <a
            href="https://www.alvarado-dev.com/"
            target="_blank"
            rel="noopener"
            className="text-primary-claro font-semibold hover:underline"
          >
            Cornerstone Develop
          </a>
        </p>
      </div>
    </footer>
  );
}
