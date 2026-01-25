type HeroBannerProps = {
  title: string;
  description?: string;
};

export default function HeroBanner({ title, description }: HeroBannerProps) {
  return (
    <section className="rounded-3xl border border-slate-200 bg-white p-8 shadow-sm">
      <div className="space-y-3">
        <p className="text-sm font-semibold uppercase tracking-[0.2em] text-slate-500">
          Store Platform
        </p>
        <h1 className="text-4xl font-semibold text-slate-900 sm:text-5xl">{title}</h1>
        {description ? <p className="text-lg text-slate-600">{description}</p> : null}
      </div>
    </section>
  );
}
