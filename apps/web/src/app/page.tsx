import { getHeroBanner, type HeroBannerContent } from "@packages/aem";
import HeroBanner from "../components/hero-banner";
import SiteNav from "../components/site-nav";

export default async function HomePage() {
  const fallbackHero: HeroBannerContent = {
    title: "Welcome to Store Platform",
    description: "Discover what’s new.",
  };
  let hero: HeroBannerContent = fallbackHero;

  try {
    hero = await getHeroBanner({ revalidateSeconds: 60 });
  } catch (error) {
    console.warn("Hero banner fetch failed; using fallback content.", error);
  }

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
