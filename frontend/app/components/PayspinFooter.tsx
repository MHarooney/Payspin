export default function PayspinFooter() {
  const year = new Date().getFullYear();
  return (
    <footer className="ps-footer">
      <div className="ps-footer__links">
        <a href="https://payspin.io/terms" target="_blank" rel="noreferrer">
          Terms
        </a>
        <span aria-hidden>·</span>
        <a href="https://payspin.io/privacy" target="_blank" rel="noreferrer">
          Privacy
        </a>
      </div>
      <span>© {year} Payspin · Your money, your community, your peace of mind.</span>
    </footer>
  );
}
