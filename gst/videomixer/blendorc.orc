.function orc_merge_linear_u8
.dest 1 d1
.source 1 s1
.source 1 s2
.param 1 p1
.temp 2 t1
.temp 2 t2
.temp 1 a
.temp 1 t

loadb a, s1
convubw t1, s1
convubw t2, s2
subw t2, t2, t1
mullw t2, t2, p1
addw t2, t2, 128
convhwb t, t2
addb d1, t, a



.function orc_merge_linear_u16
.dest 2 d1
.source 2 s1
.source 2 s2
.param 2 p1
.param 2 p2
.temp 4 t1
.temp 4 t2

# This is slightly different thatn the u8 case, since muluwl
# tends to be much faster than mulll
muluwl t1, s1, p1
muluwl t2, s2, p2
addl t1, t1, t2
shrul t1, t1, 16
convlw d1, t1


.function orc_memcpy_u32
.dest 4 d1 guint32
.source 4 s1 guint32

copyl d1, s1


.function orc_splat_u16
.dest 2 d1
.param 2 p1

copyw d1, p1


.function orc_splat_u32
.dest 4 d1
.param 4 p1

copyl d1, p1


.function orc_splat_u64
.dest 8 d1
.longparam 8 p1

copyq d1, p1


.function orc_blend_u8
.flags 2d
.dest 1 d1 guint8
.source 1 s1 guint8
.param 2 p1
.temp 2 t1
.temp 2 t2
.const 1 c1 8 

convubw t1, d1
convubw t2, s1
subw t2, t2, t1
mullw t2, t2, p1
shlw t1, t1, c1
addw t2, t1, t2
shruw t2, t2, c1
convsuswb d1, t2


.function orc_blend_argb
.flags 2d
.dest 4 d guint8
.source 4 s guint8
.param 2 alpha
.temp 4 t
.temp 2 tw
.temp 1 tb
.temp 4 a
.temp 8 d_wide
.temp 8 s_wide
.temp 8 a_wide
.const 4 a_alpha 0x000000ff

loadl t, s
convlw tw, t
convwb tb, tw
splatbl a, tb
x4 convubw a_wide, a
x4 mullw a_wide, a_wide, alpha
x4 shruw a_wide, a_wide, 8
x4 convubw s_wide, t
loadl t, d
x4 convubw d_wide, t
x4 subw s_wide, s_wide, d_wide
x4 mullw s_wide, s_wide, a_wide
x4 div255w s_wide, s_wide
x4 addw d_wide, d_wide, s_wide
x4 convwb t, d_wide
orl t, t, a_alpha
storel d, t

.function orc_blend_bgra
.flags 2d
.dest 4 d guint8
.source 4 s guint8
.param 2 alpha
.temp 4 t
.temp 4 t2
.temp 2 tw
.temp 1 tb
.temp 4 a
.temp 8 d_wide
.temp 8 s_wide
.temp 8 a_wide
.const 4 a_alpha 0xff000000

loadl t, s
shrul t2, t, 24
convlw tw, t2
convwb tb, tw
splatbl a, tb
x4 convubw a_wide, a
x4 mullw a_wide, a_wide, alpha
x4 shruw a_wide, a_wide, 8
x4 convubw s_wide, t
loadl t, d
x4 convubw d_wide, t
x4 subw s_wide, s_wide, d_wide
x4 mullw s_wide, s_wide, a_wide
x4 div255w s_wide, s_wide
x4 addw d_wide, d_wide, s_wide
x4 convwb t, d_wide
orl t, t, a_alpha
storel d, t


.function orc_overlay_argb
.flags 2d
.dest 4 d guint8
.source 4 s guint8
.param 2 alpha
.temp 4 t
.temp 2 tw
.temp 1 tb
.temp 8 alpha_s
.temp 8 alpha_s_inv
.temp 8 alpha_d
.temp 4 a
.temp 8 d_wide
.temp 8 s_wide
.const 4 xfs 0xffffffff
.const 4 a_alpha 0x000000ff
.const 4 a_alpha_inv 0xffffff00

# calc source alpha as alpha_s = alpha_s * alpha / 256
loadl t, s
convlw tw, t
convwb tb, tw
splatbl a, tb
x4 convubw alpha_s, a
x4 mullw alpha_s, alpha_s, alpha
x4 shruw alpha_s, alpha_s, 8
x4 convubw s_wide, t
x4 mullw s_wide, s_wide, alpha_s

# calc destination alpha as alpha_d = (255-alpha_s) * alpha_d / 255
loadpl a, xfs
x4 convubw alpha_s_inv, a
x4 subw alpha_s_inv, alpha_s_inv, alpha_s
loadl t, d
convlw tw, t
convwb tb, tw
splatbl a, tb
x4 convubw alpha_d, a
x4 mullw alpha_d, alpha_d, alpha_s_inv
x4 div255w alpha_d, alpha_d
x4 convubw d_wide, t
x4 mullw d_wide, d_wide, alpha_d

# calc final pixel as pix_d = pix_s*alpha_s + pix_d*alpha_d*(255-alpha_s)/255
x4 addw d_wide, d_wide, s_wide

# calc the final destination alpha_d = alpha_s + alpha_d * (255-alpha_s)/255
x4 addw alpha_d, alpha_d, alpha_s

# now normalize the pix_d by the final alpha to make it associative
x4 divluw, d_wide, d_wide, alpha_d

# pack the new alpha into the correct spot
x4 convwb t, d_wide
andl t, t, a_alpha_inv
x4 convwb a, alpha_d
andl a, a, a_alpha
orl  t, t, a
storel d, t

.function orc_overlay_bgra
.flags 2d
.dest 4 d guint8
.source 4 s guint8
.param 2 alpha
.temp 4 t
.temp 4 t2
.temp 2 tw
.temp 1 tb
.temp 8 alpha_s
.temp 8 alpha_s_inv
.temp 8 alpha_d
.temp 4 a
.temp 8 d_wide
.temp 8 s_wide
.const 4 xfs 0xffffffff
.const 4 a_alpha 0xff000000
.const 4 a_alpha_inv 0x00ffffff

# calc source alpha as alpha_s = alpha_s * alpha / 256
loadl t, s
shrul t2, t, 24
convlw tw, t2
convwb tb, tw
splatbl a, tb
x4 convubw alpha_s, a
x4 mullw alpha_s, alpha_s, alpha
x4 shruw alpha_s, alpha_s, 8
x4 convubw s_wide, t
x4 mullw s_wide, s_wide, alpha_s

# calc destination alpha as alpha_d = (255-alpha_s) * alpha_d / 255
loadpl a, xfs
x4 convubw alpha_s_inv, a
x4 subw alpha_s_inv, alpha_s_inv, alpha_s
loadl t, d
shrul t2, t, 24
convlw tw, t2
convwb tb, tw
splatbl a, tb
x4 convubw alpha_d, a
x4 mullw alpha_d, alpha_d, alpha_s_inv
x4 div255w alpha_d, alpha_d
x4 convubw d_wide, t
x4 mullw d_wide, d_wide, alpha_d

# calc final pixel as pix_d = pix_s*alpha_s + pix_d*alpha_d*(255-alpha_s)/255
x4 addw d_wide, d_wide, s_wide

# calc the final destination alpha_d = alpha_s + alpha_d * (255-alpha_s)/255
x4 addw alpha_d, alpha_d, alpha_s

# now normalize the pix_d by the final alpha to make it associative
x4 divluw, d_wide, d_wide, alpha_d

# pack the new alpha into the correct spot
x4 convwb t, d_wide
andl t, t, a_alpha_inv
x4 convwb a, alpha_d
andl a, a, a_alpha
orl  t, t, a
storel d, t

.function orc_downsample_u8
.dest 1 d1 guint8
.source 2 s1 guint8
.temp 1 t1
.temp 1 t2

splitwb t1, t2, s1
avgub d1, t1, t2


.function orc_downsample_u16
.dest 2 d1 guint16
.source 4 s1 guint16
.temp 2 t1
.temp 2 t2

splitlw t1, t2, s1
avguw d1, t1, t2


.function gst_videoscale_orc_downsample_u32
.dest 4 d1 guint8
.source 8 s1 guint8
.temp 4 t1
.temp 4 t2

splitql t1, t2, s1
x4 avgub d1, t1, t2

.function gst_videoscale_orc_downsample_yuyv
.dest 4 d1 guint8
.source 8 s1 guint8
.temp 4 yyyy
.temp 4 uvuv
.temp 2 t1
.temp 2 t2
.temp 2 yy
.temp 2 uv

x4 splitwb yyyy, uvuv, s1
x2 splitwb t1, t2, yyyy
x2 avgub yy, t1, t2
splitlw t1, t2, uvuv
x2 avgub uv, t1, t2
x2 mergebw d1, yy, uv

.function gst_videoscale_orc_resample_nearest_u8
.dest 1 d1 guint8
.source 1 s1 guint8
.param 4 p1
.param 4 p2

ldresnearb d1, s1, p1, p2


.function gst_videoscale_orc_resample_bilinear_u8
.dest 1 d1 guint8
.source 1 s1 guint8
.param 4 p1
.param 4 p2

ldreslinb d1, s1, p1, p2


.function gst_videoscale_orc_resample_nearest_u32
.dest 4 d1 guint8
.source 4 s1 guint8
.param 4 p1
.param 4 p2

ldresnearl d1, s1, p1, p2


.function gst_videoscale_orc_resample_bilinear_u32
.dest 4 d1 guint8
.source 4 s1 guint8
.param 4 p1
.param 4 p2

ldreslinl d1, s1, p1, p2


.function gst_videoscale_orc_resample_merge_bilinear_u32
.dest 4 d1 guint8
.dest 4 d2 guint8
.source 4 s1 guint8
.source 4 s2 guint8
.temp 4 a
.temp 4 b
.temp 4 t
.temp 8 t1
.temp 8 t2
.param 4 p1
.param 4 p2
.param 4 p3

ldreslinl b, s2, p2, p3
storel d2, b
loadl a, s1
x4 convubw t1, a
x4 convubw t2, b
x4 subw t2, t2, t1
x4 mullw t2, t2, p1
x4 convhwb t, t2
x4 addb d1, t, a



.function gst_videoscale_orc_merge_bicubic_u8
.dest 1 d1 guint8
.source 1 s1 guint8
.source 1 s2 guint8
.source 1 s3 guint8
.source 1 s4 guint8
.param 4 p1
.param 4 p2
.param 4 p3
.param 4 p4
.temp 2 t1
.temp 2 t2

mulubw t1, s2, p2
mulubw t2, s3, p3
addw t1, t1, t2
mulubw t2, s1, p1
subw t1, t1, t2
mulubw t2, s4, p4
subw t1, t1, t2
addw t1, t1, 32
shrsw t1, t1, 6
convsuswb d1, t1