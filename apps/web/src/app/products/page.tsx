import SiteNav from "../../components/site-nav";
import ProductCard from "../../components/product-card";

type Product = {
  id: string;
  name: string;
  price: number;
  imageUrl?: string;
  description?: string;
  category?: string;
};

async function getProducts() {
  const baseUrl = process.env.CONTENT_SERVICE_URL ?? "http://localhost:4001";
  const res = await fetch(`${baseUrl}/content/products`, {
    next: { revalidate: 60 },
  });

  if (!res.ok) {
    const text = await res.text().catch(() => "");
    throw new Error(`Failed to load products: ${res.status} ${res.statusText} ${text}`);
  }

  return (await res.json()) as Product[];
}

export default async function ProductsPage() {
  let products: Product[] = [];

  try {
    products = await getProducts();
  } catch (error) {
    console.warn("Products fetch failed; rendering empty state.", error);
  }

  return (
    <div className="flex min-h-screen flex-col bg-slate-50 md:flex-row">
      <SiteNav />
      <main className="flex-1 px-6 py-8">
        <div className="mx-auto flex w-full max-w-6xl flex-col gap-6">
          <div>
            <p className="text-sm font-semibold uppercase tracking-[0.2em] text-slate-500">
              Product Catalog
            </p>
            <h1 className="text-3xl font-semibold text-slate-900">Browse Products</h1>
          </div>
          <section className="grid gap-6 sm:grid-cols-2 lg:grid-cols-3">
            {products.length === 0 ? (
              <div className="rounded-2xl border border-dashed border-slate-200 bg-white p-6 text-sm text-slate-600">
                Products are unavailable right now. Please check back soon.
              </div>
            ) : (
              products.map((product) => (
                <ProductCard
                  key={product.id}
                  name={product.name}
                  price={product.price}
                  imageUrl={product.imageUrl}
                  description={product.description}
                  category={product.category}
                />
              ))
            )}
          </section>
        </div>
      </main>
    </div>
  );
}
