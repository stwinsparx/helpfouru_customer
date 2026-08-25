class HomeImage {
  const HomeImage({required this.id, required this.image, this.redirectUrl});

  final int id;
  final String image;
  final String? redirectUrl;

  factory HomeImage.fromJson(Map<String, dynamic> json) => HomeImage(
    id: json['id'] as int,
    image: json['image'] as String,
    redirectUrl: json['redirect_url'] as String?,
  );
}

class HomeData {
  const HomeData({
    required this.homeSliders,
    required this.homeBanner,
    required this.gallery,
  });

  final List<HomeImage> homeSliders;
  final HomeImage? homeBanner;
  final List<HomeImage> gallery;

  factory HomeData.fromJson(Map<String, dynamic> json) => HomeData(
    homeSliders: (json['homeSliders'] as List<dynamic>? ?? [])
        .map((e) => HomeImage.fromJson(e as Map<String, dynamic>))
        .toList(),
    homeBanner: json['homeBanner'] != null
        ? HomeImage.fromJson(json['homeBanner'] as Map<String, dynamic>)
        : null,
    gallery: (json['gallery'] as List<dynamic>? ?? [])
        .map((e) => HomeImage.fromJson(e as Map<String, dynamic>))
        .toList(),
  );
}
