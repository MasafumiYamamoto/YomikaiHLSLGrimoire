/**
 * \brief ベックマン分布の計算
 * \param m microfacet
 * \param t 法線とハーフベクトルとの内積
 * \return ベックマン分布
 */
float Beckmann(const float m, const float t)
{
    const float t2 = t * t;
    const float t4 = t2 * t2;
    const float m2 = m * m;
    float D = 1 / (4 * m2 * t4);
    D *= exp((-1/m2) * (1-t2)/t2);
    return D;
}

/**
 * \brief Schlick近似によるフレネルの計算
 * \param f0 垂直直入反射時のフレネル反射率
 * \param u 視点に向かうベクトルとハーフベクトルの内積
 * \return フレネル
 */
float SpcFresnel(const float f0, const float u)
{
    return f0 + (1 - f0) * pow(1 - u, 5);
}

/**
 * \brief Cook-Torranceモデルの鏡面反射を計算
 * \param surface2Light 表面から光源に向かうベクトル
 * \param toEye 視点に向かうベクトル
 * \param worldNormal 法線
 * \param metallic 金属度
 * \return 鏡面反射率
 */
float CookTorranceSpecular(const float3 surface2Light, const float3 toEye, const float3 worldNormal,
    const float metallic)
{
    const float microfacet = 0.75;

    // 金属度垂直入射の時のフレネル反射率として扱う
    // 金属度が高いほどフレネル反射は大きくなる
    const float f0 = metallic;

    // ライトへ向かうベクトルと視線に向かうベクトルのハーフベクトルを求める
    const float3 halfVector = normalize(surface2Light + toEye);

    // 各種ベクトルがどれだけ似ているかを内積を利用して求める
    const float normalDotHalf = saturate(dot(worldNormal, halfVector));
    const float eyeDotHalf = saturate(dot(toEye, halfVector));
    const float normalDotLight = saturate(dot(worldNormal, surface2Light));
    const float normalDotEye = saturate(dot(worldNormal, toEye));

    // D項をベックマン分布を用いて計算する
    const float D = Beckmann(microfacet, normalDotHalf);

    // F項をSchlick近似を用いて計算する
    const float F = SpcFresnel(f0, eyeDotHalf);

    // G項を求める
    const float G = min(1, min(2 * normalDotHalf * normalDotEye / eyeDotHalf, 2 * normalDotHalf * normalDotLight / eyeDotHalf));

    // m項を求める
    const float m = PI * normalDotEye * normalDotHalf;

    // ここまで求めた値を利用してCookTorranceモデルの鏡面反射を求める
    return max(F * D * G / m, 0);
}
