type ProductCardProps = {
  name: string;
  price: number;
  imageUrl?: string;
  description?: string;
  category?: string;
};

export default function ProductCard({
  name,
  price,
  imageUrl,
  description,
  category,
}: ProductCardProps) {
  return (
    <article className="flex h-full flex-col overflow-hidden rounded-2xl border border-slate-200 bg-white shadow-sm">
      <div className="aspect-[4/3] w-full bg-slate-100">
        {imageUrl ? (
          <img
            src={imageUrl}
            alt={name}
            className="h-full w-full object-cover"
            loading="lazy"
          />
        ) : (
          <div className="flex h-full items-center justify-center text-sm text-slate-400">
            No image
          </div>
        )}
      </div>
      <div className="flex flex-1 flex-col gap-3 p-4">
        <div className="space-y-1">
          <h3 className="text-lg font-semibold text-slate-900">{name}</h3>
          {category ? <p className="text-xs uppercase text-slate-500">{category}</p> : null}
        </div>
        {description ? <p className="text-sm text-slate-600">{description}</p> : null}
        <div className="mt-auto text-base font-semibold text-slate-900">${price.toFixed(2)}</div>
      </div>
    </article>
  );
}
