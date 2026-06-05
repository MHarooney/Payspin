/* eslint-disable @next/next/no-img-element */
export default function PayspinHeader() {
  return (
    <header className="ps-header">
      <img
        className="ps-header__logo"
        src="/payspin-logo.png"
        alt="Payspin"
        width={28}
        height={28}
      />
      <span className="ps-header__text">Pay with Payspin</span>
    </header>
  );
}
