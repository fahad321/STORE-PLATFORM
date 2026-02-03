import Link from "next/link";

export default function SiteNav() {
  return (
    <nav className="flex w-full flex-col gap-4 border-b border-slate-200 px-6 py-4 md:min-h-screen md:w-64 md:border-b-0 md:border-r">
      <div className="text-lg font-semibold text-slate-900">Store Platform</div>
      <div className="flex items-center gap-4 md:flex-col md:items-start">
        <Link className="text-slate-700 hover:text-slate-900" href="/">
          Home
        </Link>
        <Link className="text-slate-700 hover:text-slate-900" href="/products">
          Products
        </Link>
      </div>
    </nav>
  );
}
