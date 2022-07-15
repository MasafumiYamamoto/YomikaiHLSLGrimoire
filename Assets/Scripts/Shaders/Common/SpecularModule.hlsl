/**
 * \brief ディレクショナルライトスペキュラ成分を計算
 * \param lightPosWS ワールド空間での光源位置
 * \param lightColor 光源色
 * \param viewDirWS ワールド空間でのビューベクトル
 * \param normalWS ワールド空間での法線
 * \param reflectSharpness 反射強度
 * \return 
 */
float3 DirectionalSpecular(const float3 lightPosWS, const float3 lightColor, const float3 viewDirWS,
    const float3 normalWS, const float reflectSharpness)
{
    const float3 reflectVec = reflect(-lightPosWS, normalWS);
    float power = max(0, dot(viewDirWS, reflectVec));
    power = pow(power, reflectSharpness);
    return power * lightColor;
}