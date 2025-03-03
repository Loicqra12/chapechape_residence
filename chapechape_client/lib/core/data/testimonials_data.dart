import '../models/testimonial_model.dart';

class TestimonialsData {
  static final List<TestimonialModel> testimonials = [
    TestimonialModel(
      id: '1',
      userName: 'Kouamé Aya',
      userAvatar: null,
      residenceName: 'Villa Santorini',
      rating: 4.8,
      content: 'Un séjour exceptionnel dans cette villa. Le service était impeccable et les installations sont modernes et confortables.',
      date: DateTime(2024, 1, 15),
    ),
    TestimonialModel(
      id: '2',
      userName: 'Diallo Mamadou',
      userAvatar: null,
      residenceName: 'Appartement Cocody',
      rating: 4.5,
      content: 'Très bon rapport qualité-prix. Emplacement idéal au centre-ville avec toutes les commodités à proximité.',
      date: DateTime(2024, 2, 3),
    ),
    TestimonialModel(
      id: '3',
      userName: 'Traoré Fatou',
      userAvatar: null,
      residenceName: 'Studio Plateau',
      rating: 4.2,
      content: 'Studio parfait pour un court séjour professionnel. Propre, bien équipé et sécurisé.',
      date: DateTime(2024, 1, 27),
    ),
    TestimonialModel(
      id: '4',
      userName: 'Koné Ibrahim',
      userAvatar: null,
      residenceName: 'Résidence Bietry',
      rating: 4.7,
      content: 'Vue magnifique sur la lagune et personnel très attentionné. Je recommande vivement!',
      date: DateTime(2024, 2, 10),
    ),
    TestimonialModel(
      id: '5',
      userName: 'Touré Aminata',
      userAvatar: null,
      residenceName: 'Villa Assinie',
      rating: 5.0,
      content: 'Un véritable paradis au bord de la plage. Parfait pour des vacances en famille ou entre amis.',
      date: DateTime(2024, 1, 5),
    ),
  ];
}
