# World Sphere Implementation Roadmap

## Problem

The prototype has a real spherical camera model, but the world still reads as rectangular parcels pasted onto a sphere. The next architecture should make the sphere itself the world, with roads, buildings, collision, and scale all derived from spherical surface data.

## Design Principles

- Use meters as the unit system.
- Treat the player as a capsule standing on the inner shell, with local up pointing toward the sphere center.
- Keep city geometry anchored to the sphere by local tangent frames, not flat grid assumptions.
- Prefer continuous spherical bands, arcs, domes, towers, ribs, and terraces over visible rectangular cells.
- Preserve a small procedural city API so layout can evolve without rewriting rendering.

## Phases

1. **Continuous Shell Surface**
   Replace visible parcel quads with a continuous shaded inner shell and smooth road bands along spherical arcs. Parcel data may still exist for layout and collision, but it should not be visibly tiled.

2. **Spherical Road Network**
   Build roads as real spherical bands with width in meters. Roads should follow great-circle-like arcs and district loops, not per-cell center lines.

3. **Curved Building Footprints**
   Replace parcel-aligned footprints with spherical circles/ellipses expressed in local tangent coordinates. Towers, domes, and ribs should extrude inward along the local normal.

4. **Depth and Occlusion**
   Add draw ordering or migrate to real GL meshes so near geometry reliably occludes far geometry. The software projector is useful for iteration, but it will eventually limit believable world scale.

5. **Planetary Landmarks**
   Add a few large-scale objects: transit rings, central cables, hanging plazas, shell ribs, and luminous atmospheric volumes. These give the world visual hierarchy beyond player/building scale.

6. **Collision and Navigation**
   Replace parcel collision with spherical footprint collision against generated buildings and road boundaries. Add camera collision against buildings and shell features.

7. **Procedural City Data**
   Replace hard-coded city rules with a list of districts, roads, lots, landmarks, and generated building instances. Rendering and collision should consume this shared city model.

## Current Implementation Target

Implement Phase 1 now: continuous shell surface plus smooth spherical road bands, while keeping existing rounded towers and collision as a temporary compatibility layer.
