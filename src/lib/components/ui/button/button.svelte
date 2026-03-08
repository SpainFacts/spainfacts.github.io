<script>
    import { Button as ButtonPrimitive } from "bits-ui";
    import { cn } from "../../../utils.js";
    import { buttonVariants } from "./index.js"; // We need to create index.js for variants

    /** @type {string | undefined | null} */
    let className = undefined;

    /** @type {import('./index.js').Variant} */
    export let variant = "default";

    /** @type {import('./index.js').Size} */
    export let size = "default";

    /** @type {Array<*>} */
    export let builders = [];

    export { className as class };
</script>

<ButtonPrimitive.Root
    {builders}
    class={cn(
        buttonVariants({ variant, size, className }),
        "hover:bg-base-200 shadow-base-200",
    )}
    type="button"
    {...$$restProps}
    on:click
    on:keydown
>
    <slot />
</ButtonPrimitive.Root>
