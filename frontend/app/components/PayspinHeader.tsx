import PayspinEmblem from './PayspinEmblem';
import ThemeToggle from './ThemeToggle';

export default function PayspinHeader() {
  return (
    <header className="ps-header">
      <PayspinEmblem size={28} className="ps-header__logo" />
      <span className="ps-header__text">Pay with Payspin</span>
      <ThemeToggle />
    </header>
  );
}
