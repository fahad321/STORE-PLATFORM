import { getHeroBanner } from "@packages/aem";
import HeroBanner from "../components/hero-banner";

export default async function HomePage() {
  const hero = await getHeroBanner({ revalidateSeconds: 60 });

  return (
    <main className="mx-auto max-w-5xl px-6 py-10">
      <HeroBanner title={hero.title} description={hero.description} />
    </main>
  );
}
