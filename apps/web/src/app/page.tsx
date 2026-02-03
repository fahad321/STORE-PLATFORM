import { getHeroBanner } from "@packages/aem";
import HeroBanner from "../components/hero-banner";
import SiteNav from "../components/site-nav";

export default async function HomePage() {
  const hero = await getHeroBanner({ revalidateSeconds: 60 });

  return (
    <div className="flex min-h-screen flex-col bg-slate-50 md:flex-row">
      <SiteNav />
      <main className="flex-1 px-6 py-10">
        <div className="mx-auto w-full max-w-5xl">
          <HeroBanner title={hero.title} description={hero.description} />
        </div>
      </main>
    </div>
  );
}
