<script>
    import { cn } from "../../../utils.js";

    /** @type {string | undefined | null} */
    let className = undefined;

    export { className as class };
</script>

<span
    class={cn("ml-auto text-xs tracking-widest opacity-60", className)}
    {...$$restProps}
>
    <slot />
</span>
